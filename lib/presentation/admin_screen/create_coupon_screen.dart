import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_app_bar.dart';

class CreateCouponScreen extends StatefulWidget {
  const CreateCouponScreen({super.key});

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxUsageController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isPercentage = true;
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final discountValue = double.parse(_discountController.text.trim());
      final success = await AdminService.createCoupon(
        code: _codeController.text.trim().toUpperCase(),
        discountPercent: _isPercentage ? discountValue.toInt() : 0,
        expiryDate: _selectedDate,
        maxUsage: int.parse(_maxUsageController.text.trim()),
        isPercentage: _isPercentage,
        discountAmount: _isPercentage ? null : discountValue,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon created successfully! 🎫'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Create Coupon',
        style: CustomAppBarStyle.standard,
        showBackButton: true,
        showSearchButton: false,
        showCartButton: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(5.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coupon Details',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                'Define a new discount code for EGYZONE shoppers.',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 4.h),
              
              _buildTextField(
                controller: _codeController,
                label: 'Coupon Code',
                hint: 'e.g. EGY25',
                validator: (v) => v!.isEmpty ? 'Code is required' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              SizedBox(height: 3.h),
              
              Row(
                children: [
                  Text('Discount Type:'),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isPercentage,
                    onChanged: (value) {
                      setState(() {
                        _isPercentage = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(_isPercentage ? 'Percentage (%)' : 'Fixed Amount (ج.م)'),
                ],
              ),
              SizedBox(height: 3.h),
              
              _buildTextField(
                controller: _discountController,
                label: _isPercentage ? 'Discount Percentage (%)' : 'Discount Amount (ج.م)',
                hint: _isPercentage ? '0' : '0.00',
                keyboardType: _isPercentage ? TextInputType.number : TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Value is required' : null,
              ),
              SizedBox(height: 3.h),
              
              _buildTextField(
                controller: _maxUsageController,
                label: 'Max Usage Limit',
                hint: '100',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Limit is required' : null,
              ),
              SizedBox(height: 3.h),
              
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expiry Date', style: theme.textTheme.bodySmall),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Icon(Icons.calendar_today, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Generate Coupon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
    );
  }
}
