import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/utils/app_logger.dart';
// Removed fixed SomalilandCities dependency; will use free-form city input with optional autocomplete API
import '../../core/constant_categories.dart';
import '../../widgets/app_logo_widget.dart';
import '../../widgets/standard_scaffold.dart';
import 'map_picker_page.dart';
import 'my_listings_page.dart';

class CreateListingPage extends StatefulWidget {
  final Listing? listing; // For editing existing listings
  
  const CreateListingPage({super.key, this.listing});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

// Removed: free-form Nominatim suggestions model

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Form state
  CategoryItem? _selectedCategory;
  String? _selectedSubcategory;
  List<String> _subcategories = [];
  String? _selectedCity;
  String _selectedCondition = 'used'; // Default value
  final List<String> _conditionOptions = ['new', 'used'];
  bool _isNegotiable = false;
  bool _isLoading = false;

  // Somalia cities (including major cities across all regions)
  // Sorted alphabetically for better UX
  final List<String> _somaliaCities = [
    'Afgoye',
    'Afmadow',
    'Baidoa',
    'Bandarbeyla',
    'Bardera',
    'Beledweyne',
    'Berbera',
    'Bosaso',
    'Borama',
    'Burao',
    'Buurhakaba',
    'Daynile',
    'Dhusamareb',
    'Eyl',
    'Erigavo',
    'Gaalkacyo',
    'Gabiley',
    'Garbahaarrey',
    'Garoowe',
    'Hargeisa',
    'Hobyo',
    'Jamaame',
    'Jawhar',
    'Jowhar',
    'Kismayo',
    'Las Anod',
    'Luuq',
    'Merca',
    'Mogadishu',
    'Qardho',
    'Qoryooley',
    'Sheikh',
    'Wanlaweyn',
    'Wajaale',
    'Xarardheere',
    'Xuddur',
  ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  // Media
  final List<XFile> _selectedImages = [];
  List<String> _imageUrls = [];
  final List<XFile> _selectedVideos = [];
  List<String> _videoUrls = [];
  
  // Maximum limits as per database requirements
  static const int maxImages = 15;
  static const int maxVideos = 5;

  // Location
  LatLng? _selectedLocation;
  // GoogleMapController? _mapController; // Not used in this page
  // Geocoding loading state
  bool _loadingCity = false;


  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.listing != null) {
      // Edit mode - populate form with existing data
      final listing = widget.listing!;
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      _priceController.text = listing.price.toString();
      _selectedCondition = listing.condition;
      _imageUrls = List.from(listing.images);
      if (listing.videos.isNotEmpty) {
        _videoUrls = listing.videos;
      }
      _selectedCity = listing.location;
      _selectedLocation = LatLng(listing.latitude, listing.longitude);
      
      // Set category
      _selectedCategory = AppCategories.categories.firstWhere(
        (cat) => cat.id == listing.category,
        orElse: () => AppCategories.categories.first,
      );
      _updateSubcategories();
      _selectedSubcategory = listing.subcategory;
    } else {
      // Create mode - set defaults
  // Default city no longer auto-selected; user will type their city.
  _selectedCity = null;
  _selectedLocation = null; // Will be set after selecting suggestion or map
    }
  }

  // Removed: free-form city autocomplete helpers

  // Somalia-only city dropdown powered by Nominatim for coordinates
  Widget _buildCityDropdownField() {
    // If editing, ensure existing city is present in the dropdown list
    final items = List<String>.from(_somaliaCities);
    if (_selectedCity != null && _selectedCity!.isNotEmpty && !items.contains(_selectedCity)) {
      items.add(_selectedCity!);
      items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    return DropdownButtonFormField<String>(
      value: _selectedCity != null && items.contains(_selectedCity) ? _selectedCity : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'City *',
        prefixIcon: Icon(Icons.location_city, color: AppColor.primary),
        suffixIcon: _loadingCity
            ? Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColor.primary, width: 2),
        ),
      ),
      items: items.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
      onChanged: (val) async {
        setState(() {
          _selectedCity = val;
        });
        if (val != null && val.isNotEmpty) {
          await _lookupLatLonForCity(val);
        }
      },
      validator: (val) => val == null || val.isEmpty ? 'Please select a city' : null,
    );
  }

  Future<void> _lookupLatLonForCity(String city) async {
    setState(() => _loadingCity = true);
    try {
      // Limit to Somalia using countrycodes=so and prefer the best match
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q='
        '${Uri.encodeComponent('$city, Somalia')}'
        '&format=json&addressdetails=1&limit=1&countrycodes=so',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'iibsasho-app/1.0 (contact: example@example.com)'
      });
      if (resp.statusCode == 200) {
        final List list = json.decode(resp.body) as List;
        if (list.isNotEmpty) {
          final item = list.first;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            setState(() {
              _selectedLocation = LatLng(lat, lon);
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) AppLogger.w('City geocode error: $e');
    } finally {
      if (mounted) setState(() => _loadingCity = false);
    }
  }

  // Removed: old debounced Nominatim search

  void _updateSubcategories() {
    if (_selectedCategory != null) {
      setState(() {
        _subcategories = _selectedCategory!.subcategories.map((sub) => sub.name).toList();
        _selectedSubcategory = null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if ((_selectedImages.length + _imageUrls.length) >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxImages images allowed'),
          backgroundColor: AppColor.error,
        ),
      );
      return;
    }
    
    try {
      final images = await ImageUploadService.pickMultipleImages();
      if (images.isNotEmpty) {
        // Check if adding these images would exceed the limit
        final totalAfterAdd = _selectedImages.length + _imageUrls.length + images.length;
        if (totalAfterAdd > maxImages) {
          final allowedCount = maxImages - (_selectedImages.length + _imageUrls.length);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Can only add $allowedCount more image(s). Limit is $maxImages total.'),
              backgroundColor: AppColor.error,
            ),
          );
          return;
        }
        
        setState(() {
          _selectedImages.addAll(images);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} image(s) added'),
            backgroundColor: AppColor.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: AppColor.error,
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    if ((_selectedVideos.length + _videoUrls.length) >= maxVideos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxVideos videos allowed'),
          backgroundColor: AppColor.error,
        ),
      );
      return;
    }
    
    try {
      final video = await ImageUploadService.pickVideo();
      if (video != null) {
        setState(() {
          _selectedVideos.add(video);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video selected: ${video.name}'),
            backgroundColor: AppColor.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting video: $e'),
          backgroundColor: AppColor.error,
        ),
      );
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapPickerPage(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      } else {
        _imageUrls.removeAt(index - _selectedImages.length);
      }
    });
  }

  void _removeVideo(int index) {
    setState(() {
      if (index < _selectedVideos.length) {
        _selectedVideos.removeAt(index);
      } else {
        _videoUrls.removeAt(index - _selectedVideos.length);
      }
    });
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;

    // Check authentication
    if (!SupabaseHelper.requireAuth(context, feature: 'create listing')) {
      return;
    }

    // Validate required fields
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }

    if (_subcategories.isNotEmpty && _selectedSubcategory == null) {
      _showError('Please select a subcategory');
      return;
    }

    if (_selectedCity == null) {
      _showError('Please select a city');
      return;
    }

    if (_selectedImages.isEmpty && _imageUrls.isEmpty) {
      _showError('Please add at least one image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new images
      List<String> uploadedImageUrls = List.from(_imageUrls);
      if (_selectedImages.isNotEmpty) {
        final newImageUrls = await ImageUploadService.uploadImages(_selectedImages);
        uploadedImageUrls.addAll(newImageUrls);
      }

      // Upload videos if selected
      List<String> uploadedVideoUrls = List.from(_videoUrls);
      if (_selectedVideos.isNotEmpty) {
        final newVideoUrls = await ImageUploadService.uploadVideos(_selectedVideos);
        uploadedVideoUrls.addAll(newVideoUrls);
      }

  // Determine coordinates: if user picked map use that else leave 0/0 placeholder (later geocoding step)
  final finalLocation = _selectedLocation ?? const LatLng(0,0);

      // Create listing object
      final user = SupabaseHelper.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final listing = Listing(
        id: widget.listing?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        category: _selectedCategory!.id,
        subcategory: _selectedSubcategory ?? '',
        condition: _selectedCondition,
  location: _selectedCity ?? '',
        latitude: finalLocation.latitude,
        longitude: finalLocation.longitude,
        images: uploadedImageUrls,
        videos: uploadedVideoUrls,
        userId: user.id, // Ensure this matches the logged-in user's ID
        userName: user.userMetadata?['name'] ?? user.email ?? 'Unknown User',
        userEmail: user.email ?? '',
        userPhotoUrl: user.userMetadata?['photo_url'] ?? '',
        createdAt: widget.listing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        viewCount: widget.listing?.viewCount ?? 0,
        isFeatured: widget.listing?.isFeatured ?? false,
        isPromoted: (widget.listing is Listing) ? (widget.listing as Listing).isPromoted : false,
        isDraft: widget.listing?.isDraft ?? false,
      );

      // Save to backend
      String? listingId;
      if (widget.listing == null) {
        listingId = await ListingService.createListing(listing);
      } else {
        await ListingService.updateListing(listing.id, listing);
        listingId = listing.id;
      }

      if (listingId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listing == null 
                ? 'Listing created successfully!' 
                : 'Listing updated successfully!'),
            backgroundColor: AppColor.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyListingsPage()),
        );
      } else {
        _showError('Failed to save listing. Please try again.');
      }
    } catch (e) {
      _showError('Error saving listing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDraft() async {
    if (!SupabaseHelper.requireAuth(context, feature: 'save draft')) return;
    // Minimal validation: need at least a title to draft
    if (_titleController.text.trim().isEmpty) {
      _showError('Add a title before saving draft');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = SupabaseHelper.currentUser;
      if (user == null) throw Exception('Not authenticated');
      // Create lightweight listing object (images/videos optional)
      final listing = Listing(
        id: widget.listing?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
  price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        category: _selectedCategory?.id ?? '',
        subcategory: _selectedSubcategory ?? '',
        condition: _selectedCondition,
        location: _selectedCity ?? 'Unknown',
        latitude: _selectedLocation?.latitude ?? 0,
        longitude: _selectedLocation?.longitude ?? 0,
        images: _imageUrls, // Not uploading draft media yet
        videos: _videoUrls,
        userId: user.id,
        userName: user.userMetadata?['name'] ?? user.email ?? 'Unknown User',
        userEmail: user.email ?? '',
        userPhotoUrl: user.userMetadata?['photo_url'] ?? '',
        createdAt: widget.listing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
        viewCount: widget.listing?.viewCount ?? 0,
        isFeatured: widget.listing?.isFeatured ?? false,
        isPromoted: widget.listing?.isPromoted ?? false,
        isDraft: true,
      );
      String? id;
      if (widget.listing == null) {
        id = await ListingService.createListing(listing);
      } else {
        await ListingService.updateListing(listing.id, listing);
        id = listing.id;
      }
      if (id == null) throw Exception('Failed to save draft');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Draft saved'), backgroundColor: AppColor.success),
      );
    } catch (e) {
      _showError('Draft error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardScaffold(
      title: widget.listing == null ? 'Create Listing' : 'Edit Listing',
      currentIndex: 2,
      showBottomNav: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AppLogoWidget(height: 24, width: 24, isWhiteVersion: true),
        ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildCategorySection(),
              SizedBox(height: 24),
              _buildLocationSection(),
              SizedBox(height: 24),
              _buildMediaSection(),
              SizedBox(height: 24),
              _buildMapSection(),
              SizedBox(height: 32),
              _buildSaveButton(),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _saveDraft,
                      icon: Icon(Icons.save_alt, color: AppColor.primary),
                      label: Text('Save Draft', style: TextStyle(color: AppColor.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColor.primary),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  if (widget.listing?.isDraft == true)
                    Expanded(
                      child: ElevatedButton.icon(
            onPressed: _isLoading
              ? null
              : () async {
                // Publish: mark draft inactive->active
                                if (widget.listing == null) return;
                                setState(() => _isLoading = true);
                                try {
                                  final l = widget.listing!;
                                  final updated = Listing(
                                    id: l.id,
                                    title: l.title,
                                    description: l.description,
                                    images: l.images,
                                    videos: l.videos,
                                    price: l.price,
                                    category: l.category,
                                    subcategory: l.subcategory,
                                    location: l.location,
                                    latitude: l.latitude,
                                    longitude: l.longitude,
                                    condition: l.condition,
                                    userId: l.userId,
                                    userName: l.userName,
                                    userEmail: l.userEmail,
                                    userPhotoUrl: l.userPhotoUrl,
                                    createdAt: l.createdAt,
                                    updatedAt: DateTime.now(),
                                    isActive: true,
                                    viewCount: l.viewCount,
                                    isFeatured: l.isFeatured,
                                    isPromoted: l.isPromoted,
                                    isDraft: false,
                                  );
                                  await ListingService.updateListing(l.id, updated);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Draft published'), backgroundColor: AppColor.success),
                                  );
                                } catch (e) {
                                  _showError('Publish failed: $e');
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                        icon: Icon(Icons.publish),
                        label: Text('Publish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 16),
          
          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter a descriptive title',
              prefixIcon: Icon(Icons.title, color: AppColor.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              if (value.trim().length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
            maxLength: 100,
          ),
          SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe your item in detail',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.description, color: AppColor.primary),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.primary, width: 2),
              ),
            ),
            maxLines: 5,
            maxLength: 1000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              if (value.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          
          // Price and Negotiable
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price (\$) *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money, color: AppColor.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.primary, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price < 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColor.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      'Negotiable',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _isNegotiable,
                    onChanged: (value) {
                      setState(() {
                        _isNegotiable = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                    activeColor: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Condition
          DropdownButtonFormField<String>(
            value: _selectedCondition,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Condition *',
              prefixIcon: Icon(Icons.star_rate, color: AppColor.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.primary, width: 2),
              ),
            ),
            items: _conditionOptions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCondition = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 16),
          
          // Category dropdown
          DropdownButtonFormField<CategoryItem>(
            value: _selectedCategory,
            dropdownColor: AppColor.cardBackground,
            isExpanded: true,
            style: TextStyle(
              color: AppColor.textDark,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Category *',
              prefixIcon: Icon(Icons.category, color: AppColor.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColor.primary, width: 2),
              ),
            ),
            items: AppCategories.categories.map((category) {
              return DropdownMenuItem<CategoryItem>(
                value: category,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, color: AppColor.primary, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        category.name,
                        style: TextStyle(color: AppColor.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _updateSubcategories();
              });
              AppLogger.d('Category selected: ${value?.name}');
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          
          // Subcategory dropdown
          if (_subcategories.isNotEmpty) ...[
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubcategory,
              dropdownColor: AppColor.cardBackground,
              isExpanded: true,
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Subcategory *',
                prefixIcon: Icon(Icons.subdirectory_arrow_right, color: AppColor.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColor.primary, width: 2),
                ),
              ),
              items: _subcategories.map((subcategory) {
                return DropdownMenuItem<String>(
                  value: subcategory,
                  child: Text(
                    subcategory,
                    style: TextStyle(color: AppColor.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubcategory = value;
                });
                AppLogger.d('Subcategory selected: $value');
              },
              validator: (value) {
                if (_subcategories.isNotEmpty && value == null) {
                  return 'Please select a subcategory';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 16),
          
          _buildCityDropdownField(),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Photos & Video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textDark,
                ),
              ),
              Spacer(),
              Text(
                '${_selectedImages.length + _imageUrls.length}/$maxImages',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Add up to $maxImages photos and $maxVideos videos',
            style: TextStyle(
              fontSize: 12,
              color: AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          
          // Image picker button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_selectedImages.length + _imageUrls.length) < maxImages
                  ? _pickImages
                  : null,
              icon: Icon(Icons.photo_library),
              label: Text((_selectedImages.length + _imageUrls.length) < maxImages 
                  ? 'Add Photos' 
                  : 'Image Limit Reached'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColor.primary),
                foregroundColor: AppColor.primary,
              ),
            ),
          ),
          
          // Images preview
          if (_selectedImages.isNotEmpty || _imageUrls.isNotEmpty) ...[
            SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + _imageUrls.length,
                itemBuilder: (context, index) {
                  if (index < _selectedImages.length) {
                    // New selected images
                    final image = _selectedImages[index];
                    return _buildImagePreview(
                      imageFile: image,
                      onRemove: () => _removeImage(index),
                    );
                  } else {
                    // Existing uploaded images
                    final urlIndex = index - _selectedImages.length;
                    final imageUrl = _imageUrls[urlIndex];
                    return _buildImagePreview(
                      imageUrl: imageUrl,
                      onRemove: () => _removeImage(index),
                    );
                  }
                },
              ),
            ),
          ],
          
          SizedBox(height: 16),
          
          // Video picker section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Videos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textDark,
                    ),
                  ),
                  Text(
                    '${_selectedVideos.length + _videoUrls.length}/$maxVideos',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.placeholder,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Video picker button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_selectedVideos.length + _videoUrls.length) < maxVideos ? _pickVideo : null,
                  icon: Icon(Icons.videocam),
                  label: Text((_selectedVideos.length + _videoUrls.length) < maxVideos 
                      ? 'Add Video (Optional)' 
                      : 'Video Limit Reached'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColor.accent),
                    foregroundColor: AppColor.accent,
                  ),
                ),
              ),
              
              // Video preview list
              if (_selectedVideos.isNotEmpty || _videoUrls.isNotEmpty) ...[
                SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _selectedVideos.length + _videoUrls.length,
                  itemBuilder: (context, index) {
                    if (index < _selectedVideos.length) {
                      // Local video file
                      final video = _selectedVideos[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColor.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColor.accent.withOpacity(0.3)),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_filled, 
                                       color: AppColor.accent, size: 32),
                                  SizedBox(height: 4),
                                  Text(
                                    video.name.length > 15 
                                        ? '${video.name.substring(0, 15)}...' 
                                        : video.name,
                                    style: TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeVideo(index),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColor.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Uploaded video URL
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColor.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColor.success.withOpacity(0.3)),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_filled, 
                                       color: AppColor.success, size: 32),
                                  SizedBox(height: 4),
                                  Text(
                                    'Uploaded Video',
                                    style: TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeVideo(index),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColor.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview({XFile? imageFile, String? imageUrl, required VoidCallback onRemove}) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageFile != null
                ? (kIsWeb
                    ? FutureBuilder<Uint8List>(
                        future: imageFile.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.image),
                          );
                        },
                      )
                    : Image.file(
                        File(imageFile.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ))
                : Image.network(
                    imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColor.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precise Location (Optional)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Set a precise location on the map to help buyers find you',
            style: TextStyle(
              fontSize: 12,
              color: AppColor.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          
          // Map button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickLocation,
              icon: Icon(Icons.map),
              label: Text(_selectedLocation != null 
                  ? 'Update Location on Map' 
                  : 'Set Location on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Location info
          if (_selectedLocation != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColor.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColor.success),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location set: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                      '${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveListing,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(widget.listing == null ? 'Creating...' : 'Updating...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.listing == null ? Icons.add : Icons.save),
                  SizedBox(width: 8),
                  Text(
                    widget.listing == null ? 'Create Listing' : 'Update Listing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
