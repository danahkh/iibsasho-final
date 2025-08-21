import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
// Firebase imports removed (migrated to Supabase). TODO: Implement Supabase storage upload.
import 'package:flutter_svg/flutter_svg.dart';
// Firestore import removed. Replace GeoPoint with a simple data holder or Supabase PostGIS if enabled.
class GeoPoint { // Minimal replacement until Supabase location modeling decided
  final double latitude;
  final double longitude;
  GeoPoint(this.latitude, this.longitude);
}
import 'package:flutter/foundation.dart' show kIsWeb;
=======
>>>>>>> c9b83a2 (Backup and sync: create local backup folder and prepare push to final repo)
import '../../core/model/listing.dart';
import 'create_listing_page.dart';

class ListingFormPage extends StatelessWidget {
  final Listing? listing;
  
  const ListingFormPage({super.key, this.listing});

  @override
<<<<<<< HEAD
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
      // TODO: Upload images/videos to Supabase storage buckets and collect URLs.
      // Placeholder: no upload performed.
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Media upload failed: $e')));
      return;
    }
    // Get current user
  // TODO: Replace with Supabase auth user id
  final userId = ''; // SupabaseHelper.currentUser?.id ?? '';
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
  userId: userId,
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
=======
>>>>>>> c9b83a2 (Backup and sync: create local backup folder and prepare push to final repo)
  Widget build(BuildContext context) {
    return CreateListingPage(listing: listing);
  }
}
