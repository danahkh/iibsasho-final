import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constant/app_color.dart';
import 'package:iibsasho/core/model/listing.dart';
import 'package:iibsasho/core/services/listing_service.dart';
import 'package:iibsasho/views/widgets/item_card.dart';

class SearchResultPage extends StatefulWidget {
  final String searchKeyword;
  const SearchResultPage({super.key, required this.searchKeyword});

  @override
  _SearchResultPageState createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> with TickerProviderStateMixin {
  late TabController tabController;
  TextEditingController searchInputController = TextEditingController();
  List<Listing> searchedListings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    searchInputController.text = widget.searchKeyword;
    tabController = TabController(length: 4, vsync: this);
    _searchListings();
  }

  Future<void> _searchListings() async {
    setState(() => isLoading = true);
    // Example: fetch all listings and filter by keyword (replace with Firestore query for production)
    final allListings = await ListingService().getListings().first;
    searchedListings = allListings.where((listing) =>
      listing.title.toLowerCase().contains(widget.searchKeyword.toLowerCase()) ||
      listing.description.toLowerCase().contains(widget.searchKeyword.toLowerCase())
    ).toList();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            'assets/icons/Arrow-left.svg',
            color: AppColor.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SvgPicture.asset(
              'assets/icons/iibsashologo.svg',
              height: 32,
              width: 32,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/Filter.svg',
              color: Colors.white,
            ),
          ),
        ],
        title: SizedBox(
          height: 40,
          child: TextField(
            autofocus: false,
            controller: searchInputController,
            style: TextStyle(fontSize: 14, color: Colors.white),
            onSubmitted: (value) {
              setState(() {
                searchedListings = [];
                isLoading = true;
              });
              _searchListings();
            },
            decoration: InputDecoration(
              hintStyle: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.3)),
              hintText: 'Find a products...',
              prefixIcon: Container(
                padding: EdgeInsets.all(10),
                child: SvgPicture.asset('assets/icons/Search.svg', color: Colors.white),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent, width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              fillColor: Colors.white.withOpacity(0.1),
              filled: true,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            color: AppColor.secondary,
            child: TabBar(
              controller: tabController,
              indicatorColor: AppColor.accent,
              indicatorWeight: 5,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'poppins', fontSize: 12),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontFamily: 'poppins', fontSize: 12),
              tabs: [
                Tab(
                  text: 'Related',
                ),
                Tab(
                  text: 'Newest',
                ),
                Tab(
                  text: 'Popular',
                ),
                Tab(
                  text: 'Best Seller',
                ),
              ],
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // 1 - Related
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16, top: 16),
                      child: Text(
                        'Search result of ${widget.searchKeyword}',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: searchedListings.isEmpty
                            ? [Text('No results found.', style: TextStyle(color: Colors.grey))]
                            : searchedListings.map((listing) => ItemCard(
                                listing: listing, // Update ItemCard to accept Listing
                              )).toList(),
                      ),
                    ),
                  ],
                ),
          SizedBox(),
          SizedBox(),
          SizedBox(),
        ],
      ),
    );
  }
}
