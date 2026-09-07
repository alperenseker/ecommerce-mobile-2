// Referansta bu ekranın tamamı YORUMDA (`TDummyData` üstüne kurulmuştu ve
// hiçbir rotadan açılmıyordu). Ürün detayındaki "yorumlar" sekmesi ve
// tam ekran liste `product_detail/widgets/product_review_screen.dart`
// içindeki `SingleProductReviewsScreen` ile çiziliyor; puan dağılımı ise
// bu klasördeki `widgets/progress_indicator_and_rating.dart` ile.
//
// KURALLAR §4 gereği dosya silinmedi; referanstaki hâliyle duruyor. Buradaki
// `ProductReviewsScreen` adı, yorum YAZMA ekranındaki sınıfla çakışıyor
// (`screens/review/review_screen.dart`) — referansta da öyle, çakışma
// yaşanmamasının sebebi bu dosyanın tamamının yorumda olması.
//
// import 'package:flutter/material.dart';
//
// import '../../../../common/widgets/appbar/appbar.dart';
// import '../../../../utils/constants/sizes.dart';
// import 'widgets/progress_indicator_and_rating.dart';
// import 'widgets/rating_star.dart';
//
// class ProductReviewsScreen extends StatelessWidget {
//   const ProductReviewsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       /// -- Başlık
//       appBar: TAppBar(title: Text('Reviews & Ratings'), showBackArrow: true),
//
//       /// -- Gövde
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(TSizes.defaultSpace),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Ratings and reviews are verified and are from people who use the same type of device that you use."),
//               SizedBox(height: TSizes.spaceBtwItems),
//
//               /// Genel puan
//               TOverallProductRating(),
//               TRatingBarIndicator(rating: 3.5),
//               Text("12,611"),
//               SizedBox(height: TSizes.spaceBtwSections),
//
//               /// Kullanıcı yorumları
//               // ListView.separated(
//               //   shrinkWrap: true,
//               //   itemCount: TDummyData.productReviews.length,
//               //   physics: const NeverScrollableScrollPhysics(),
//               //   separatorBuilder: (_, __) => const SizedBox(height: TSizes.spaceBtwSections),
//               //   itemBuilder: (_, index) => UserReviewCard(productReview: TDummyData.productReviews[index]),
//               // )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
