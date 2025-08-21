import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/core/model/Search.dart';
import 'package:iibsasho/views/screens/search_result_page.dart';
import 'package:iibsasho/views/widgets/popular_search_card.dart';
import 'package:iibsasho/views/widgets/search_history_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<SearchHistory> listSearchHistory = [];
  List<PopularSearch> listPopularSearch = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _titleSuggestions = [];
  List<String> _categorySuggestions = [];
  bool _loadingSuggestions = false;
  static const _historyKey = 'search_history_list';

  void _onSearchChanged() {
    final term = _searchController.text.trim();
    if (term.length < 2) {
      setState(() {
        _titleSuggestions = [];
        _categorySuggestions = [];
      });
      return;
    }
    _fetchSuggestions(term);
  }

  Future<void> _fetchSuggestions(String term) async {
    setState(() => _loadingSuggestions = true);
    final data = await ListingService.fetchSuggestions(term);
    if (!mounted) return;
    setState(() {
      _titleSuggestions = data['titles'] ?? [];
      _categorySuggestions = data['categories'] ?? [];
      _loadingSuggestions = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  _loadHistory();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColor.primary,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset('assets/icons/Arrow-left.svg', color: Colors.white),
        ),
        title: Row(
          children: [
            Text('iibsasho',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.8,
                  shadows: [
                    Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black.withOpacity(0.3)),
                  ],
                )),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 40,
                child: Stack(
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        final term = value.trim();
                        if (term.isEmpty) return;
                        _goToResults(term);
                      },
                      style: TextStyle(fontSize: 14, color: AppColor.textPrimary),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(fontSize: 14, color: AppColor.placeholder),
                        hintText: 'Search products, categories...',
                        prefixIcon: Icon(Icons.search, color: AppColor.iconSecondary, size: 20),
                        suffixIcon: _loadingSuggestions
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(
                                icon: Icon(Icons.arrow_forward, color: AppColor.primary),
                                onPressed: () {
                                  final term = _searchController.text.trim();
                                  if (term.isEmpty) return;
                                  _goToResults(term);
                                },
                              ),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                        filled: true,
                        fillColor: AppColor.inputBackground,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColor.inputBorder, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColor.primary.withOpacity(.6), width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    if ((_titleSuggestions.isNotEmpty || _categorySuggestions.isNotEmpty) && _focusNode.hasFocus)
                      Positioned(
                        top: 44,
                        left: 0,
                        right: 0,
                        child: Material(
                          color: AppColor.primary.withOpacity(0.98),
                          elevation: 6,
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 260),
                            child: ListView(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              children: [
                                if (_categorySuggestions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                    child: Text('Categories', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: .5)),
                                  ),
                                ..._categorySuggestions.map((c) => _SuggestionTile(label: c, icon: Icons.folder_open, onTap: () => _goToResults(c))),
                                if (_titleSuggestions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                    child: Text('Titles', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: .5)),
                                  ),
                                ..._titleSuggestions.map((t) => _SuggestionTile(label: t, icon: Icons.text_snippet_outlined, onTap: () => _goToResults(t))),
                              ],
                            ),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: (listSearchHistory.isEmpty && listPopularSearch.isEmpty)
          ? Center(child: Text('No search history or popular searches yet.'))
          : ListView(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              children: [
                // Section 1 - Search History
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Search history...',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: listSearchHistory.length,
                      itemBuilder: (context, index) {
                        return SearchHistoryTile(
                          data: listSearchHistory[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SearchResultPage(
                                  searchKeyword: listSearchHistory[index].title,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        onPressed: _clearHistory,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppColor.primary.withOpacity(0.3), backgroundColor: AppColor.primarySoft,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        ),
                        child: Text(
                          'Delete search history',
                          style: TextStyle(color: AppColor.secondary.withOpacity(0.6)),
                        ),
                      ),
                    ),
                  ],
                ),
                // Section 2 - Popular Search
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Popular search.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                    ),
                    Wrap(
                      direction: Axis.horizontal,
                      children: List.generate(listPopularSearch.length, (index) {
                        return PopularSearchCard(
                          data: listPopularSearch[index],
                          onTap: () {},
                        );
                      }),
                    ),
                  ],
                )
              ],
            ),
    );
  }

  void _goToResults(String term) {
    setState(() {
      _titleSuggestions = [];
      _categorySuggestions = [];
    });
    _addToHistory(term);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultPage(searchKeyword: term),
      ),
    );
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_historyKey) ?? [];
    setState(() {
      listSearchHistory = items.map((e) => SearchHistory(title: e)).toList();
    });
  }

  Future<void> _addToHistory(String term) async {
    if (term.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_historyKey) ?? [];
    // Move existing to front or add new
    items.removeWhere((e) => e.toLowerCase() == term.toLowerCase());
    items.insert(0, term);
    // Cap size
    if (items.length > 25) {
      items.removeRange(25, items.length);
    }
    await prefs.setStringList(_historyKey, items);
    setState(() {
      listSearchHistory = items.map((e) => SearchHistory(title: e)).toList();
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() {
      listSearchHistory = [];
    });
  }
}

class _SuggestionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SuggestionTile({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            SizedBox(width: 8),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// End of file
