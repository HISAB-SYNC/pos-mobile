import 'package:flutter/foundation.dart' hide Category;

import '../data/category_repository.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  List<Category> _categories = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadCategories({
    required String shopId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.getCategories(
      shopId: shopId,
      token: token,
    );

    _isLoading = false;

    if (response['success'] == true) {
      final data = response['data'] as List<dynamic>;

      _categories = data
          .map(
            (item) => Category.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to load categories';

    notifyListeners();
    return false;
  }

  Future<bool> createCategory({
    required String shopId,
    required String name,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.createCategory(
      shopId: shopId,
      name: name,
      token: token,
    );

    _isLoading = false;

    if (response['success'] == true) {
      final category = Category.fromJson(
        response['data'] as Map<String, dynamic>,
      );

      _categories.add(category);

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to create category';

    notifyListeners();
    return false;
  }

  Future<bool> updateCategory({
    required String shopId,
    required String categoryId,
    required String name,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.updateCategory(
      shopId: shopId,
      categoryId: categoryId,
      name: name,
      token: token,
    );

    _isLoading = false;

    if (response['success'] == true) {
      final updatedCategory = Category.fromJson(
        response['data'] as Map<String, dynamic>,
      );

      final index = _categories.indexWhere(
        (category) => category.id == updatedCategory.id,
      );

      if (index != -1) {
        _categories[index] = updatedCategory;
      }

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to update category';

    notifyListeners();
    return false;
  }

  Future<bool> deleteCategory({
    required String shopId,
    required String categoryId,
    required String token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _repository.deleteCategory(
      shopId: shopId,
      categoryId: categoryId,
      token: token,
    );

    _isLoading = false;

    if (response['success'] == true) {
      _categories.removeWhere(
        (category) => category.id == categoryId,
      );

      notifyListeners();
      return true;
    }

    _errorMessage =
        response['error'] as String? ?? 'Failed to delete category';

    notifyListeners();
    return false;
  }

  void clear() {
    _categories = [];
    _errorMessage = null;
    notifyListeners();
  }
}