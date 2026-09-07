// Referansta bu widget'ın tamamı YORUMDA: artık var olmayan bir modele
// (`ProductReviewModel` — `userImageUrl`, `companyComment`, `timestamp`)
// dayanıyor ve hiçbir yerden çağrılmıyor. Yorum kartının çalışan hâli
// `product_detail/widgets/t_review_card.dart` içindeki `ReviewCard`.
//
// KURALLAR §4 gereği dosya silinmedi, referanstaki hâliyle duruyor.
//
// import 'package:flutter/material.dart';
// import 'package:readmore/readmore.dart';
//
// import '../../../../../utils/constants/colors.dart';
// import '../../../../../utils/formatters/formatter.dart';
// import '../../../../../utils/helpers/helper_functions.dart';
// import '../../../models/product_review_model.dart';
// import 'rating_star.dart';
//
// class UserReviewCard extends StatelessWidget {
//   const UserReviewCard({super.key, required this.productReview});
//
//   final ProductReviewModel productReview;
//
//   @override
//   Widget build(BuildContext context) {
//     final dark = THelperFunctions.isDarkMode(context);
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(backgroundImage: AssetImage(productReview.userImageUrl ?? '')),
//                 const SizedBox(width: 10.0),
//                 Text(productReview.userName ?? '', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400)),
//               ],
//             ),
//             IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
//           ],
//         ),
//         const SizedBox(height: 10.0),
//
//         /// Yorum
//         Row(
//           children: [
//             TRatingBarIndicator(rating: productReview.rating),
//             const SizedBox(width: 10.0),
//             Text(TFormatter.formatDate(productReview.timestamp)),
//           ],
//         ),
//         const SizedBox(height: 10.0),
//
//         ReadMoreText(
//           productReview.comment ?? '',
//           trimLines: 3,
//           colorClickableText: Colors.blue,
//           trimMode: TrimMode.Line,
//           trimExpandedText: '  show less',
//           moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
//           lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
//         ),
//         const SizedBox(height: 10.0),
//
//         /// Mağaza cevabı
//         Container(
//           color: dark ? TColors.darkerGrey : TColors.grey,
//           child: Padding(
//             padding: const EdgeInsets.all(15.0),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text("T's Store", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500)),
//                     Text(TFormatter.formatDate(productReview.companyTimestamp)),
//                   ],
//                 ),
//                 const SizedBox(height: 10.0),
//                 ReadMoreText(
//                   productReview.companyComment ?? '',
//                   trimLines: 3,
//                   colorClickableText: Colors.blue,
//                   trimMode: TrimMode.Line,
//                   trimExpandedText: '  show less',
//                   moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
//                   lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
