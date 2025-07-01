import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import 'map_picker_page.dart';
import '../../constant/app_color.dart';
import '../../core/constant_categories.dart';

class ListingFormPage extends StatefulWidget {
  final Listing? listing;
  const ListingFormPage({super.key, this.listing});

  @override
  State<ListingFormPage> createState() => _ListingFormPageState();
}

class _ListingFormPageState extends State<ListingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  quill.QuillController descriptionController = quill.QuillController.basic();
  String condition = 'used';
  LatLng? selectedLocation;
  String address = '';
  bool isLoading = false;
  List<XFile> images = [];
  List<XFile> videos = [];
  final ImagePicker _picker = ImagePicker();
  // Remove old staticCategories and use AppCategories.categories
  CategoryItem? selectedCategory;
  String? selectedSubcategory;
  List<String> subcategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.listing != null) {
      titleController.text = widget.listing!.title;
      priceController.text = widget.listing!.price.toString();
      descriptionController = quill.QuillController(
        document: quill.Document()..insert(0, widget.listing!.description),
        selection: const TextSelection.collapsed(offset: 0),
      );
      condition = widget.listing!.condition;
      // Set location and address from listing if editing
      if (widget.listing != null) {
        selectedLocation = LatLng(widget.listing!.location.latitude, widget.listing!.location.longitude);
        address = widget.listing!.address;
      }
      // Set selectedCategory using AppCategories
      selectedCategory = AppCategories.categories.firstWhere(
        (cat) => cat.name == widget.listing!.category,
        orElse: () => AppCategories.categories.first,
      );
      subcategories = selectedCategory?.subcategories ?? [];
      // If you want to support editing subcategory, set selectedSubcategory here
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapPickerPage(initialLocation: selectedLocation),
      ),
    );
    if (result != null) {
      setState(() {
        selectedLocation = result;
        address = 'Lat: ${result.latitude}, Lng: ${result.longitude}';
      });
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images = picked;
      });
    }
  }

  void _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        videos.add(picked);
      });
    }
  }

  void _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category.')));
      return;
    }
    if (subcategories.isNotEmpty && (selectedSubcategory == null || selectedSubcategory!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a subcategory.')));
      return;
    }
    setState(() => isLoading = true);
    List<String> imageUrls = [];
    List<String> videoUrls = [];
    try {
      for (var img in images) {
        final ref = FirebaseStorage.instance.ref().child('listing_images/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
        if (kIsWeb) {
          await ref.putData(await img.readAsBytes()).timeout(const Duration(seconds: 30));
        } else {
          await ref.putFile(File(img.path)).timeout(const Duration(seconds: 30));
        }
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
      for (var vid in videos) {
        final ref = FirebaseStorage.instance.ref().child('listing_videos/${DateTime.now().millisecondsSinceEpoch}_${vid.name}');
        if (kIsWeb) {
          await ref.putData(await vid.readAsBytes()).timeout(const Duration(minutes: 2));
        } else {
          await ref.putFile(File(vid.path)).timeout(const Duration(minutes: 2));
        }
        final url = await ref.getDownloadURL();
        videoUrls.add(url);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Media upload failed: $e')));
      return;
    }
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    final listing = Listing(
      id: widget.listing?.id ?? '',
      title: titleController.text,
      description: descriptionController.document.toPlainText(),
      images: imageUrls,
      videos: videoUrls,
      price: double.tryParse(priceController.text) ?? 0,
      location: selectedLocation != null ?
        GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude) : GeoPoint(0, 0),
      address: address,
      condition: condition,
      userId: user?.uid ?? '',
      createdAt: DateTime.now(),
      isActive: true,
      category: selectedCategory?.name ?? '',
      // If you want to save subcategory, add it to Listing model and save here
    );
    if (widget.listing == null) {
      await ListingService().createListing(listing);
    } else {
      await ListingService().updateListing(listing.id, listing.toMap());
    }
    setState(() => isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(title: Text(widget.listing == null ? 'Create Listing' : 'Edit Listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 32,
              width: 32,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Enter a price' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: condition,
              items: const [
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(value: 'used', child: Text('Used')),
              ],
              onChanged: (v) => setState(() => condition = v ?? 'used'),
              decoration: const InputDecoration(labelText: 'Condition'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryItem>(
              value: selectedCategory,
              items: AppCategories.categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Text(cat.name),
                  ],
                ),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  selectedCategory = v;
                  selectedSubcategory = null;
                  subcategories = v != null ? v.subcategories : [];
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            if (subcategories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedSubcategory,
                items: subcategories.map((sub) => DropdownMenuItem(
                  value: sub,
                  child: Text(sub),
                )).toList(),
                onChanged: (v) => setState(() => selectedSubcategory = v),
                decoration: const InputDecoration(labelText: 'Subcategory'),
                validator: (v) => v == null || v.isEmpty ? 'Select a subcategory' : null,
              ),
            const SizedBox(height: 12),
            Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              height: 150,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: quill.QuillEditor.basic(
                controller: descriptionController,
              ),
            ),
            // Only show video picker and video previews on mobile (not web)
            ElevatedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map),
              label: Text(selectedLocation == null ? 'Pick Location' : 'Location Selected'),
            ),
            const SizedBox(height: 12),
            Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ...images.map((img) => kIsWeb
                    ? FutureBuilder<Uint8List>(
                        future: img.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            );
                          } else {
                            return Container(width: 80, height: 80, color: Colors.grey[200]);
                          }
                        },
                      )
                    : Image.file(
                        File(img.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )),
                IconButton(
                  icon: Icon(Icons.add_a_photo),
                  onPressed: _pickImages,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Only show video section if not web
            if (!kIsWeb) ...[
              Text('Videos', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ...videos.map((vid) => Icon(Icons.videocam, size: 40, color: Colors.blue)),
                  IconButton(
                    icon: Icon(Icons.add_to_photos),
                    onPressed: _pickVideo,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _saveListing,
              child: Text(isLoading ? 'Saving...' : 'Save Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
