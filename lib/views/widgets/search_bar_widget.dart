import 'package:flutter/material.dart';
import '../../core/model/listing.dart';
import '../../core/services/listing_service.dart';

class _SearchBarWidget extends StatefulWidget {
  @override
  State<_SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<_SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  List<Listing> _results = [];
  bool _showResults = false;
  bool _loading = false;
  bool _showFullResults = false;

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
        _showFullResults = false;
      });
      return;
    }
    setState(() { _loading = true; });
    final allListings = await ListingService().fetchListings();
    final filtered = allListings.where((l) =>
      l.title.toLowerCase().contains(query.toLowerCase()) ||
      l.description.toLowerCase().contains(query.toLowerCase()) ||
      l.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
    setState(() {
      _results = filtered;
      _showResults = true;
      _loading = false;
      _showFullResults = false;
    });
  }

  void _onSearchSubmitted(String query) async {
    if (query.isEmpty) return;
    setState(() { _loading = true; });
    final allListings = await ListingService().fetchListings();
    final filtered = allListings.where((l) =>
      l.title.toLowerCase().contains(query.toLowerCase()) ||
      l.description.toLowerCase().contains(query.toLowerCase()) ||
      l.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
    setState(() {
      _results = filtered;
      _showResults = false;
      _showFullResults = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          decoration: InputDecoration(
            hintText: 'Search listings...',
            prefixIcon: Icon(Icons.search),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_showResults && !_showFullResults)
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: _loading
                ? Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                : _results.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No suggestions found.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length > 5 ? 5 : _results.length,
                      itemBuilder: (context, index) {
                        final listing = _results[index];
                        return ListTile(
                          title: Text(listing.title),
                          subtitle: Text(listing.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            // Optionally navigate to detail page
                          },
                        );
                      },
                    ),
          ),
        if (_showFullResults)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: _loading
                ? Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                : _results.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No results found.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final listing = _results[index];
                        return ListTile(
                          title: Text(listing.title),
                          subtitle: Text(listing.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            // Optionally navigate to detail page
                          },
                        );
                      },
                    ),
          ),
      ],
    );
  }
}
