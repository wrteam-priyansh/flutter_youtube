import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late YoutubePlayerController _youtubePlayerController;

  late final AnimationController controlsMenuAnimationController =
      AnimationController(vsync: this, duration: Duration(milliseconds: 500));

  late Animation<double> controlsMenuAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: controlsMenuAnimationController, curve: Curves.easeInOut));

  //need to use this to ensure youtube controller disposed properlly
  late bool assignedVideoController = false;

  final double youtubePlayerPotraitHeightPercentage = 0.3;

  @override
  void dispose() {
    controlsMenuAnimationController.dispose();
    _youtubePlayerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadYoutubeController();
  }

  void loadYoutubeController({String? videoUrl}) {
    String youTubeId = YoutubePlayer.convertUrlToId(
            videoUrl ?? "https://www.youtube.com/watch?v=q_Xa81PQlEw") ??
        "";

    _youtubePlayerController = YoutubePlayerController(
        initialVideoId: youTubeId,
        flags: YoutubePlayerFlags(
          hideThumbnail: true,
          hideControls: true,
          autoPlay: false,
        ));
    assignedVideoController = true;
  }

  //related videos
  Widget _buildOtherVideos() {
    return Expanded(
      child: ListView.builder(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height *
                  (youtubePlayerPotraitHeightPercentage)),
          itemCount: 10,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () async {
                //Video controller assigned to given youtube player
                assignedVideoController = false;
                setState(() {});
                //
                await Future.delayed(Duration(milliseconds: 100));
                //disposing youtube controller
                _youtubePlayerController.dispose();
                loadYoutubeController(videoUrl: "https://youtu.be/0plZSJIPKdM");
                setState(() {});
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
                color: Colors.blue,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * (0.175),
              ),
            );
          }),
    );
  }

  //To show play/pause button and and other control related details
  Widget _buildVideoControlMenuContainer() {
    return AnimatedBuilder(
        animation: controlsMenuAnimationController,
        builder: (context, child) {
          return Opacity(
            opacity: controlsMenuAnimation.value,
            child: GestureDetector(
              onTap: () {
                if (controlsMenuAnimationController.isCompleted) {
                  controlsMenuAnimationController.reverse();
                } else {
                  controlsMenuAnimationController.forward();
                }
              },
              child: Container(
                child: Stack(
                  children: [
                    Center(
                      child: PlayPauseButton(
                          youtubePlayerController: _youtubePlayerController,
                          controlsAnimationController:
                              controlsMenuAnimationController),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: VideoControlsContainer(
                          youtubePlayerController: _youtubePlayerController,
                          controlsAnimationController:
                              controlsMenuAnimationController),
                    ),
                  ],
                ),
                color: Colors.black45,
              ),
            ),
          );
        });
  }

  //To display the youtube video
  Widget _buildYoutubeVideoContainer(Orientation orientation) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      //changed the height of youtube player based on orientation
      height: orientation == Orientation.landscape
          ? MediaQuery.of(context).size.height
          : MediaQuery.of(context).size.height *
              youtubePlayerPotraitHeightPercentage,
      child: Stack(children: [
        Positioned.fill(
          child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                  actionsPadding: EdgeInsets.all(0),
                  onReady: () {
                    controlsMenuAnimationController.forward();
                  },
                  controller: _youtubePlayerController),
              builder: (context, player) {
                return player;
              }),
        ),

        //show controls
        _buildVideoControlMenuContainer(),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
        appBar: orientation == Orientation.landscape ? null : AppBar(),
        body: Stack(
          children: [
            orientation == Orientation.landscape
                ? SizedBox()
                : _buildOtherVideos(),
            assignedVideoController
                ? _buildYoutubeVideoContainer(orientation)
                :
                //need to show the balnk container when changing the youtube video
                //It has the same size as youtube player container
                Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height *
                        youtubePlayerPotraitHeightPercentage,
                    color: Colors.transparent,
                  ),
          ],
        ),
      );
    });
  }
}

class PlayPauseButton extends StatefulWidget {
  final AnimationController controlsAnimationController;
  final YoutubePlayerController youtubePlayerController;
  PlayPauseButton(
      {Key? key,
      required this.youtubePlayerController,
      required this.controlsAnimationController})
      : super(key: key);

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> {
  bool _isPlaying = false;

  bool _isCompleted = false;

  void listener() {
    _isPlaying = widget.youtubePlayerController.value.isPlaying;

    if (widget.youtubePlayerController.value.position.inSeconds != 0) {
      _isCompleted = widget.youtubePlayerController.value.position.inSeconds ==
          widget.youtubePlayerController.value.metaData.duration.inSeconds;
    }
    setState(() {});
  }

  @override
  void initState() {
    widget.youtubePlayerController.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.youtubePlayerController.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        iconSize: 40,
        color: Colors.white,
        onPressed: () async {
          //
          if (!widget.controlsAnimationController.isCompleted) {
            return;
          }

          if (_isCompleted) {
            widget.youtubePlayerController.seekTo(Duration.zero);
            widget.youtubePlayerController.play();
            return;
          }

          if (_isPlaying) {
            widget.youtubePlayerController.pause();
            await Future.delayed(Duration(milliseconds: 500));
            widget.controlsAnimationController.reverse();
          } else {
            widget.youtubePlayerController.play();
            await Future.delayed(Duration(milliseconds: 500));
            widget.controlsAnimationController.reverse();
          }
        },
        icon: _isCompleted
            ? Icon(Icons.restart_alt)
            : _isPlaying
                ? Icon(Icons.pause)
                : Icon(Icons.play_arrow),
      ),
    );
  }
}

class VideoControlsContainer extends StatefulWidget {
  final AnimationController controlsAnimationController;
  final YoutubePlayerController youtubePlayerController;
  VideoControlsContainer(
      {Key? key,
      required this.controlsAnimationController,
      required this.youtubePlayerController})
      : super(key: key);

  @override
  State<VideoControlsContainer> createState() => _VideoControlsContainerState();
}

class _VideoControlsContainerState extends State<VideoControlsContainer> {
  late Duration currentVideoDuration = Duration.zero;
  final double sliderHeight = 4.0;

  void listener() {
    currentVideoDuration = widget.youtubePlayerController.value.position;

    setState(() {});
  }

  bool _allowGesture() {
    return widget.controlsAnimationController.isCompleted;
  }

  String _buildCurrentVideoDurationInHMS() {
    String time = "";
    if (currentVideoDuration.inHours != 0) {
      time = "${currentVideoDuration.inHours.toString().padLeft(2, '0')}:";
    }
    if (currentVideoDuration.inMinutes != 0) {
      time =
          "${time}${(currentVideoDuration.inMinutes - (24 * currentVideoDuration.inHours)).toString().padLeft(2, '0')}:";
    }
    if (currentVideoDuration.inSeconds != 0) {
      time =
          "${time}${(currentVideoDuration.inSeconds - (60 * currentVideoDuration.inMinutes)).toString().padLeft(2, '0')}";
    }
    return time;
  }

  String _buildVideoDurationInHMS() {
    Duration videoDuration = widget.youtubePlayerController.metadata.duration;
    String time = "";
    if (videoDuration.inHours != 0) {
      time = "${(videoDuration.inHours).toString().padLeft(2, '0')}:";
    }
    if (videoDuration.inMinutes != 0) {
      time =
          "${time}${(videoDuration.inMinutes - (24 * videoDuration.inHours)).toString().padLeft(2, '0')}:";
    }
    if (videoDuration.inSeconds != 0) {
      time =
          "${time}${(videoDuration.inSeconds - (60 * videoDuration.inMinutes)).toString().padLeft(2, '0')}";
    }
    return time;
  }

  @override
  void initState() {
    widget.youtubePlayerController.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.youtubePlayerController.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  _buildCurrentVideoDurationInHMS().isEmpty
                      ? ""
                      : "${_buildCurrentVideoDurationInHMS()} / ${_buildVideoDurationInHMS()}",
                  style: TextStyle(color: Colors.white),
                ),
                Spacer(),
                IconButton(
                    color: Colors.white,
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      if (_allowGesture()) {
                        if (MediaQuery.of(context).orientation ==
                            Orientation.portrait) {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeRight,
                            DeviceOrientation.landscapeLeft
                          ]);
                        } else {
                          SystemChrome.setPreferredOrientations(
                              [DeviceOrientation.portraitUp]);
                        }
                      }
                    },
                    icon: Icon(Icons.fullscreen))
              ],
            ),
          ),
          SizedBox(
            height: sliderHeight,
            width: MediaQuery.of(context).size.width,
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 0.0),
                    trackHeight: sliderHeight,
                    trackShape: CustomTrackShape(),
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
              child: Slider(
                  max: widget
                      .youtubePlayerController.value.metaData.duration.inSeconds
                      .toDouble(),
                  min: 0.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                  value: currentVideoDuration.inSeconds.toDouble(),
                  thumbColor: Colors.blueAccent,
                  onChanged: (value) {
                    if (_allowGesture()) {
                      setState(() {
                        currentVideoDuration = Duration(
                          seconds: value.toInt(),
                        );
                      });
                      widget.youtubePlayerController
                          .seekTo(currentVideoDuration);
                    }
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTrackShape extends RectangularSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    return Offset(offset.dx, offset.dy) &
        Size(parentBox.size.width, sliderTheme.trackHeight!);
  }
}
