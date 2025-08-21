// Clean, unified implementation of SearchResultPage with blue top bar and functional tabs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import '../../constant/app_color.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';
import '../../core/services/saved_search_service.dart';
import '../widgets/item_card.dart';

class SearchResultPage extends StatefulWidget {
  final String searchKeyword;
  const SearchResultPage({super.key, required this.searchKeyword});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Listing> _results = [];
  bool _loading = true;
  String _currentSort = 'relevance';
  double? minPrice, maxPrice, radiusKm;
  double? userLat, userLng;
  String? category, subcategory;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchKeyword;
    _currentQuery = widget.searchKeyword;
    _init();
  }

  Future<void> _init() async {
    await _maybeGetLocation();
    await _performSearch();
  }

  Future<void> _maybeGetLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      userLat = pos.latitude;
      userLng = pos.longitude;
    } catch (_) {}
  }

  Future<void> _performSearch() async {
    setState(() => _loading = true);
    try {
      _results = await ListingService.searchListings(
        query: _searchController.text.trim(),
        category: category,
        subcategory: subcategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        userLat: userLat,
        userLng: userLng,
        maxDistanceKm: radiusKm,
        sortBy: _currentSort,
      );
      _currentQuery = _searchController.text.trim();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _openFilterSheet() async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColor.primary,
      isScrollControlled: true,
      builder: (ctx) {
        final minC = TextEditingController(text: minPrice?.toStringAsFixed(0) ?? '');
        final maxC = TextEditingController(text: maxPrice?.toStringAsFixed(0) ?? '');
        final radC = TextEditingController(text: radiusKm?.toStringAsFixed(0) ?? '');
        String localSort = _currentSort;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx, setM) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filters & Sort', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white))
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Price Range', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(children: [
                      Expanded(child: TextField(controller: minC, keyboardType: TextInputType.number, decoration: _fieldDecoration('Min'), style: const TextStyle(color: Colors.white))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: maxC, keyboardType: TextInputType.number, decoration: _fieldDecoration('Max'), style: const TextStyle(color: Colors.white))),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Radius (km)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    TextField(controller: radC, keyboardType: TextInputType.number, decoration: _fieldDecoration('e.g. 25'), style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text('Sort By', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final s in ['relevance', 'newest', 'price_low_high', 'price_high_low', 'popularity', 'distance', 'promoted', 'featured'])
                        ChoiceChip(label: Text(s, style: const TextStyle(fontSize: 11)), selected: localSort == s, onSelected: (_) => setM(() => localSort = s))
                    ]),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: ElevatedButton(onPressed: () {
                        Navigator.pop(ctx, {
                          'minPrice': double.tryParse(minC.text),
                          'maxPrice': double.tryParse(maxC.text),
                          'radiusKm': double.tryParse(radC.text),
                          'sort': localSort,
                        });
                      }, child: const Text('Apply'))),
                    ]),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => Navigator.pop(ctx, {'clear': true}), child: const Text('Clear Filters', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
    if (res != null) {
      if (res['clear'] == true) {
        minPrice = maxPrice = radiusKm = null;
        _currentSort = 'relevance';
      } else {
        minPrice = res['minPrice'];
        maxPrice = res['maxPrice'];
        radiusKm = res['radiusKm'];
        _currentSort = res['sort'] ?? _currentSort;
      }
      _performSearch();
    }
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        filled: true,
        fillColor: Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      );

  Future<void> _saveCurrentSearch() async {
    await SavedSearchService.create(
      query: _searchController.text.trim(),
      category: category,
      subcategory: subcategory,
      minPrice: minPrice,
      maxPrice: maxPrice,
      radiusKm: radiusKm,
      sortBy: _currentSort,
      notificationsEnabled: false,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 2,
        shadowColor: AppColor.shadowColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset('assets/icons/Arrow-left.svg', color: Colors.white),
        ),
        title: Row(
          children: [
            Text(
              'iibsasho',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                letterSpacing: -0.8,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColor.textPrimary, fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search products, categories...',
                    hintStyle: TextStyle(color: AppColor.placeholder, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColor.iconSecondary, size: 20),
                    filled: true,
                    fillColor: AppColor.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColor.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColor.primary.withOpacity(.6)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _openFilterSheet, icon: SvgPicture.asset('assets/icons/Filter.svg', color: Colors.white), tooltip: 'Filters'),
          IconButton(onPressed: _saveCurrentSearch, icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white), tooltip: 'Save search'),
          const SizedBox(width: 4),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(
        children: [
          _buildSortCategories(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildSortCategories() {
    final sorts = const [
      {'label': 'Related', 'value': 'relevance'},
      {'label': 'Newest', 'value': 'newest'},
      {'label': 'Popular', 'value': 'popularity'},
      {'label': 'Best Seller', 'value': 'promoted'},
    ];
    return Container(
      width: double.infinity,
      color: AppColor.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final s in sorts) ...[
            _buildSortChip(label: s['label'] as String, value: s['value'] as String),
            const SizedBox(width: 8),
          ]
        ],
      ),
    );
  }

  Widget _buildSortChip({required String label, required String value}) {
    final bool selected = _currentSort == value;
    return GestureDetector(
      onTap: () {
        if (selected) return;
        setState(() {
          _currentSort = value;
        });
        _performSearch();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : AppColor.primary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? Colors.white : AppColor.primary),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColor.primary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Results for "$_currentQuery" (${_results.length})',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (minPrice != null || maxPrice != null || radiusKm != null || _currentSort != 'relevance')
                  TextButton(
                    onPressed: () {
                      minPrice = maxPrice = radiusKm = null;
                      _currentSort = 'relevance';
                      _performSearch();
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            ),
          ),
          _buildActiveFilterChips(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _results.isEmpty
                  ? _emptyState()
                  : _results.map((l) => ItemCard(listing: l)).toList(),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _emptyState() => [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('No results found.', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tips:', style: TextStyle(color: Colors.black54, fontSize: 12)),
            Text('- Try broader keywords\n- Remove filters\n- Increase radius', style: TextStyle(color: Colors.black45, fontSize: 11)),
          ],
        )
      ];

  Widget _buildActiveFilterChips() {
    final chips = <Widget>[];
    void add(String label, VoidCallback onRemove) {
      chips.add(Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Chip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: onRemove,
        ),
      ));
    }
    if (minPrice != null || maxPrice != null) {
      final range = '${minPrice?.toStringAsFixed(0) ?? '0'} - ${maxPrice?.toStringAsFixed(0) ?? '∞'}';
      add('Price $range', () {
        minPrice = maxPrice = null;
        _performSearch();
      });
    }
    if (radiusKm != null) {
      add('≤ ${radiusKm!.toStringAsFixed(0)} km', () {
        radiusKm = null;
        _performSearch();
      });
    }
    if (_currentSort != 'relevance') {
      add('Sort: $_currentSort', () {
        _currentSort = 'relevance';
        _performSearch();
      });
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
      child: Row(children: chips),
    );
  }
}
