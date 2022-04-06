import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late YoutubePlayerController _youtubePlayerController;

  @override
  void dispose() {
    _youtubePlayerController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadYoutubeController();
  }

  void loadYoutubeController() {
    String youTubeId = YoutubePlayerController.convertUrlToId(
            "https://www.youtube.com/watch?v=q_Xa81PQlEw") ??
        "";
    print(youTubeId);
    _youtubePlayerController = YoutubePlayerController(
      initialVideoId: youTubeId,
      params: YoutubePlayerParams(
        privacyEnhanced: false,
        showFullscreenButton: true,
        useHybridComposition: true,
      ),
    );
    _youtubePlayerController.onEnterFullscreen = () {
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    };
    _youtubePlayerController.onExitFullscreen = () {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      _youtubePlayerController.play();
    };
  }

  Widget _buildOtherVideos() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
      color: Colors.blue,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * (0.175),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: OrientationBuilder(builder: (context, orientation) {
        return Column(
          children: [
            YoutubePlayerIFrame(
              controller: _youtubePlayerController,
              aspectRatio: 16 / 9,
            ),
            orientation == Orientation.portrait
                ? Expanded(
                    child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return _buildOtherVideos();
                        }))
                : SizedBox()
          ],
        );
      }),
    );
  }
}
