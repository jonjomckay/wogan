import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  final String uri;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const CachedImage({Key? key, required this.uri, this.width, this.height, this.fit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      uri,
      cache: true,
      filterQuality: FilterQuality.high,
      width: width,
      height: height,
      fit: fit,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Center(child: CircularProgressIndicator());
          case LoadState.failed:
            return Center(child: Icon(Icons.error));
          default:
            return state.completedWidget;
        }
      },
    );
  }
}
