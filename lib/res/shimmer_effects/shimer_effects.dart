// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';

// class ShimmerEffects {
//   //!  ----------Shimmer Effect (Loading Skeleton) ---------------
//   static Widget shimmerEffect(
//       {required double width,
//       required double height,
//       Color? baseColor,
//       Color? highlightColor}) {
//     return Shimmer.fromColors(
//       baseColor: baseColor ?? Colors.grey.shade300,
//       highlightColor: highlightColor ?? Colors.grey.shade100,
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }

//   //! ------------------Shimmer Effect for Profile AppBar----------------------
//   static Widget shimmerProfile({Color? baseColor, Color? highlightColor}) {
//     return Shimmer.fromColors(
//       baseColor: baseColor ?? Colors.grey.shade300,
//       highlightColor: highlightColor ?? Colors.grey.shade100,
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Container(
//             width: 100,
//             height: 15,
//             color: Colors.white,
//           ),
//         ],
//       ),
//     );
//   }
// }
