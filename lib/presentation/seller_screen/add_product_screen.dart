import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/providers/category_provider.dart';
import '../../core/services/seller_service.dart';
import '../../widgets/custom_app_bar.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  
  final _newCategoryController = TextEditingController();
  final _newSubCategoryController = TextEditingController();
  final _brandNameController = TextEditingController();
  bool _useNewCategory = false;
  bool _useNewSubCategory = false;

  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Fetch categories when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_useNewCategory && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a category')),
      );
      return;
    }
    if (!_useNewSubCategory && _selectedSubCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a subcategory')),
      );
      return;
    }
    if (_useNewCategory && _newCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new category name')),
      );
      return;
    }
    if (_useNewSubCategory && _newSubCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new subcategory name')),
      );
      return;
    }
    if (_brandNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a brand name')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await SellerService.createProduct(
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        categoryId: _useNewCategory ? 0 : _selectedCategoryId!,
        subCategoryId: _useNewSubCategory ? 0 : _selectedSubCategoryId!,
        categoryName: _useNewCategory ? _newCategoryController.text.trim() : null,
        subCategoryName: _useNewSubCategory ? _newSubCategoryController.text.trim() : null,
        brandName: _brandNameController.text.trim(),
        imagePaths: _selectedImages.map((e) => e.path).toList(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully! 🎉'),
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
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Add New Product',
        style: CustomAppBarStyle.standard,
        showBackButton: true,
        showSearchButton: false,
        showCartButton: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Images',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              _buildImagePicker(colorScheme),
              SizedBox(height: 3.h),
              
              Text(
                'Basic Information',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g. Nike Air Max 270',
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _priceController,
                label: 'Price (EGP)',
                hint: '0.00',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Price is required' : null,
              ),
              SizedBox(height: 2.h),
              
              Text(
                'Brand',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildBrandDropdown(),
              SizedBox(height: 2.h),
              
              Text(
                'Categorization',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildCategoryDropdown(categoryProvider),
              SizedBox(height: 2.h),
              _buildSubCategoryDropdown(categoryProvider),
              SizedBox(height: 3.h),
              
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildTextField(
                controller: _descriptionController,
                label: 'Full Description',
                hint: 'Describe your product features, materials, and sizing...',
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Description is required' : null,
              ),
              SizedBox(height: 4.h),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Publish Product',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(ColorScheme colorScheme) {
    return SizedBox(
      height: 15.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 15.h,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
                  SizedBox(height: 1.h),
                  Text('Add Photos', style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                ],
              ),
            ),
          ),
          ...List.generate(_selectedImages.length, (index) {
            return Padding(
              padding: EdgeInsets.only(left: 3.w),
              child: Stack(
                children: [
                  Container(
                    width: 15.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImages[index].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return _buildTextField(
      controller: _brandNameController,
      label: 'Brand Name',
      hint: 'e.g. Nike, Apple, Samsung',
    );
  }

  Widget _buildCategoryDropdown(CategoryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_useNewCategory)
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: provider.categories.map((cat) {
              return DropdownMenuItem(
                value: cat.categoryId,
                child: Text(cat.name),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategoryId = val;
                _selectedSubCategoryId = null; // reset subcategory
              });
            },
          )
        else
          _buildTextField(
            controller: _newCategoryController,
            label: 'New Category Name',
            hint: 'e.g. Sports & Outdoor',
          ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _useNewCategory = !_useNewCategory;
              if (!_useNewCategory) _newCategoryController.clear();
            });
          },
          icon: Icon(_useNewCategory ? Icons.list : Icons.add_circle_outline, size: 18),
          label: Text(_useNewCategory ? 'Select from list' : 'Create new category'),
        ),
      ],
    );
  }

  Widget _buildSubCategoryDropdown(CategoryProvider provider) {
    final subcategories = _selectedCategoryId == null || _useNewCategory
        ? []
        : provider.categories
            .firstWhere((c) => c.categoryId == _selectedCategoryId)
            .subCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_useNewSubCategory)
          DropdownButtonFormField<int>(
            initialValue: _selectedSubCategoryId,
            decoration: InputDecoration(
              labelText: 'Sub Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: subcategories.map<DropdownMenuItem<int>>((sub) {
              return DropdownMenuItem<int>(
                value: sub.subCategoryId,
                child: Text(sub.name),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSubCategoryId = val;
              });
            },
            disabledHint: Text(_useNewCategory ? 'Creating new category...' : 'Select a category first'),
          )
        else
          _buildTextField(
            controller: _newSubCategoryController,
            label: 'New Sub Category Name',
            hint: 'e.g. Hiking Gear',
          ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _useNewSubCategory = !_useNewSubCategory;
              if (!_useNewSubCategory) _newSubCategoryController.clear();
            });
          },
          icon: Icon(_useNewSubCategory ? Icons.list : Icons.add_circle_outline, size: 18),
          label: Text(_useNewSubCategory ? 'Select from list' : 'Create new subcategory'),
        ),
      ],
    );
  }
}
