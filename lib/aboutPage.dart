import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12, top: 12),
            child: IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade200,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                  )
              ),
              onPressed: () {
                pushScreenWithNavBar(context, ContactPage());
              },
              icon: RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.phone_enabled_outlined),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: const Text("About Us", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),),
            ),
            AboutImage(id: 1),
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: const Text(
                  '''Welcome to the academic powerhouse of NIT Calicut — the Central Library. A legacy of knowledge since 1961, it stands as one of South India’s premier technical libraries. Spanning a vast 11,340 square meters, it houses an impressive collection of over 1,35,000 books in science, engineering, and technology.
Serving a dynamic community of over 8,000 users — including undergraduate and postgraduate students, research scholars, faculty, and staff — the library is at the core of the institute’s academic and research excellence.

Open daily from 8 AM to 12 Midnight, it supports both early risers and night owls.
              '''
              ),
            ),
            AboutImage(id: 2),
            SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: const Text(
                '''Smart. Seamless. Student-Centric.
The library is fully automated, providing both on-campus and remote access through modern digital infrastructure. Key features include:
•  KOHA Library Management System for efficient navigation
•  RFID technology for quick check-ins and check-outs
•  500-user seating capacity with advanced facilities
•  Online catalog for easy search and reservations

What Sets It Apart?
Unlike rule-bound academic spaces, this library follows a need-based, user-first philosophy. It’s designed to empower users through open access and responsive services.
Whether you're studying, researching, or exploring new ideas, the Central Library is your gateway to knowledge — always connected, always evolving.
                '''
              ),
            ),
            AboutImage(id: 3),
            SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }

}

class AboutImage extends StatelessWidget {
  final int id;

  const AboutImage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {

    return SizedBox(height: 201, width: 370,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.fill,
            child:  Image.asset("assets/about_img_$id.png"),
          )
      ),
    );
  }

}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.arrow_back)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 68.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Reach Us", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),),
            SizedBox(height: 8,),
            Wrap(
              children: [
                const Text("If you have any suggestions, questions, or need any assistance with anything related to library, dont hesistate to reach out-our team is always here and happy to reach you")
              ],
            ),
            SizedBox(height: 8,),
            IconWithText(icon: Icons.mail, text:"library@nitc.ac.in"),
            SizedBox(height: 8,),
            IconWithText(icon: Icons.phone, text:"04952286063"),
            SizedBox(height: 8,),
            IconWithText(icon: Icons.location_on_sharp, text:"NIT Calicut, NIT Campus P.O\nKozhikode,Kerala, India\n673601"),
            SizedBox(height: 16,),
            SocialSection()
          ],
        ),
      ),
    );
  }
}

class IconWithText extends StatelessWidget {
  final IconData? icon;
  final String text;

  const IconWithText({
    super.key, required this.icon, required this.text
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple,),
          SizedBox(width: 8,),
          Text(text)
        ],
      ),
    );
  }
}

class SocialSection extends StatefulWidget {
  const SocialSection({super.key});

  @override
  State<SocialSection> createState() => _SocialSectionState();
}

class _SocialSectionState extends State<SocialSection> {
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if(!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        _showErrorSnackBar("Could not launch $url");
      }
    } catch(e) {
      _showErrorSnackBar("An error occured $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return FittedBox(
              child: Row(
                children: [
                  const Text("Follow Us", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600), ),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.instagram, color: Colors.deepPurple,),
                     onPressed: () => _launchUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), //! PUT ACTUAL URLS
                  ),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.xTwitter, color: Colors.deepPurple,),
                     onPressed: () => _launchUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), //! PUT ACTUAL URLS
                  ),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.facebook, color: Colors.deepPurple,),
                     onPressed: () => _launchUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), //! PUT ACTUAL URLS
                  ),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.linkedinIn, color: Colors.deepPurple,),
                     onPressed: () => _launchUrl("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), //! PUT ACTUAL URLS
                  ),
                ],
              ),
            );
  }
}