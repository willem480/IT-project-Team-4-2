import 'package:flutter/material.dart';
import 'package:ticketing_app/main.dart';



class Profile extends StatefulWidget {


  const Profile({
    super.key,
});

  @override
  State<Profile> createState() => _ProfilePage();
  
}



class _ProfilePage extends State<Profile> {
  bool is_Detail_Tab = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(

        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

      ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //intro
                  Container(
                    height: 300,
                    width: 500,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey), 
                    ),

                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)), 
                          const SizedBox(height: 20),
                          Text('\$ Total money',style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 6),
                          Text('This month: \$ money and times payouts', style: const TextStyle(fontWeight:FontWeight.bold, fontSize: 30, color: Colors.grey)),
                        ],
                    )
                  ),
                  const SizedBox(height:20),

                  //button
                  Row(
                    children: [
                      _buildTabButton('details', is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = true);

                      }),
                      const SizedBox(width: 12),
                      _buildTabButton('comment', !is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = false);
                      })
                    ],
                  ),
                  SizedBox(height: 16),

                  is_Detail_Tab ? _buildDetailsSection() : _buildCommentsSection(), 


                  

                ],
              ),


          )),
          
          Text(
            '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
      
      floatingActionButton: Padding( 
        padding: EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: 200,
          height: 80,
          child: FloatingActionButton(
          onPressed: () {Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Find a job')), (Route<dynamic> route) => false);},
          backgroundColor: Colors.blue,
          shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Text('OK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
          )
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }

  // The Details View (Description + Map)
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('The HVAC unit in the North Wing is not cooling properly...', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        // Placeholder for Map Integration
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.location_on, color: Colors.red, size: 40)),
        ),
      ],
    );
  }


  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add a comment...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
  // Helper method for the pill-shaped toggle buttons
  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade800 : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


}