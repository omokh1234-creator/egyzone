import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/review_model.dart';
import '../../../core/services/review_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/report_service.dart';

class ProductReviewsWidget extends StatefulWidget {
  final dynamic productId;
  final double rating;
  final int reviewCount;
  final Function(int count, double avgRating)? onReviewsUpdated;

  const ProductReviewsWidget({
    super.key,
    required this.productId,
    required this.rating,
    required this.reviewCount,
    this.onReviewsUpdated,
  });

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  List<ProductReview> _reviews = [];
  bool _isLoading = true;

  int get _parsedProductId {
    if (widget.productId is int) return widget.productId;
    return int.tryParse(widget.productId.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews = await ReviewService.getProductReviews(_parsedProductId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
        
        // Notify parent of the real-time count and rating
        if (widget.onReviewsUpdated != null) {
          final count = reviews.length;
          final double avg = count > 0 
              ? reviews.fold(0.0, (sum, r) => sum + r.rating) / count 
              : widget.rating;
          widget.onReviewsUpdated!(count, avg);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _reportReview(int reviewId) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      Navigator.pushNamed(context, '/login-screen');
      return;
    }

    final reasonController = TextEditingController();
    final theme = Theme.of(context);

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this review?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (submitted == true && reasonController.text.trim().isNotEmpty) {
      try {
        await ReportService.createReport(
          contentType: 'Review',
          contentId: reviewId,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Reviews',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!authProvider.isLoggedIn)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login-screen'),
                      child: const Text('Login to Review'),
                    )
                  else if (_reviews.any((r) => r.userId?.toString() == currentUserId))
                    const Text('Already Reviewed', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                  else
                    TextButton(
                      onPressed: () => _showWriteReviewDialog(context, theme),
                      child: const Text('Write a Review'),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.rating.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < widget.rating.floor()
                              ? Icons.star
                              : (index < widget.rating
                                  ? Icons.star_half
                                  : Icons.star_border),
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    Text(
                      'Based on ${_isLoading ? widget.reviewCount : _reviews.length} reviews',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final bool isPossiblyMine = review.userId == null || review.userId == 0;
                final bool isOwner = currentUserId != null && 
                    (review.userId?.toString() == currentUserId || isPossiblyMine);

                return _ReviewItem(
                  review: review,
                  isOwner: isOwner,
                  onReport: () => _reportReview(review.reviewId!),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(BuildContext context, ThemeData theme) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Write a Review', style: theme.textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How would you rate this product?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 2.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4.0,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 2.h),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a comment'),
                              ),
                            );
                            return;
                          }
                          setState(() => isSubmitting = true);
                          final newReview = ProductReview(
                            productId: _parsedProductId,
                            rating: selectedRating,
                            comment: commentController.text.trim(),
                          );
                          try {
                            final result = await ReviewService.submitReviewWithResponse(newReview);
                            if (context.mounted) {
                              if (result['success'] == true) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Review submitted successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchReviews();
                              } else {
                                if (result['message'].toString().contains('401')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Session expired. Please login again.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  await AuthService.clearAuthData();
                                  if (context.mounted) Navigator.pushNamed(context, '/login-screen');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed: ${result['message']}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                setState(() => isSubmitting = false);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: Text(isSubmitting ? 'Submitting...' : 'Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ProductReview review;
  final bool isOwner;
  final VoidCallback onReport;

  const _ReviewItem({
    required this.review,
    required this.isOwner,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    
    final dateStr = review.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(review.createdAt!)
        : 'Recently';

    // Fallback name logic:
    // 1. If isOwner, use current user's name from provider
    // 2. Otherwise use the API name or 'Anonymous'
    final String displayName;
    if (isOwner && authProvider.currentUser != null) {
      displayName = authProvider.currentUser!.fullName ?? 'You';
    } else {
      displayName = review.userName ?? 'Anonymous User';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOwner ? theme.colorScheme.primary : null,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isOwner)
                IconButton(
                  icon: Icon(Icons.flag_outlined, color: theme.colorScheme.onSurfaceVariant, size: 20),
                  onPressed: onReport,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Report review',
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              review.comment!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
