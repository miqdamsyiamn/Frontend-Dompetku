import 'package:dio/dio.dart';
import 'auth_manager.dart';
import '/model/user_model.dart';
import '/model/transaction_model.dart';
import '/model/goal_model.dart';
import '/model/summary_model.dart';

class ApiService {
  // Base URL untuk API
  static const String baseUrl = 'https://dompetku-mu.vercel.app';
  // static const String baseUrl = 'http://localhost:8080'; // untuk development

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initDio();
  }

  late final Dio _dio;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthManager().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Map<String, dynamic> _handleResponse(Response response) {
    return response.data as Map<String, dynamic>;
  }

  /// Handle API error
  ApiException _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      String message = 'Unknown error occurred';

      // Handle both String and Map response data
      if (data is Map) {
        message = data['error'] ?? data['message'] ?? message;
      } else if (data is String) {
        message = data;
      }

      return ApiException(
        statusCode: error.response!.statusCode ?? 500,
        message: message,
      );
    }
    return ApiException(
      statusCode: 0,
      message: error.message ?? 'Network error occurred',
    );
  }

  /// Register user baru
  Future<AuthResponse> register({
    required String nama,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {'nama': nama, 'username': username, 'password': password},
      );
      return AuthResponse.fromJson(_handleResponse(response));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(_handleResponse(response));

      // Simpan token ke AuthManager
      if (authResponse.token != null) {
        await AuthManager().saveToken(authResponse.token!);
        if (authResponse.user != null) {
          await AuthManager().saveUser(authResponse.user!.toJson());
        }
      }

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/api/user/profile');
      final data = _handleResponse(response);
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String nama,
    String? filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nama': nama,
        if (filePath != null)
          'foto': await MultipartFile.fromFile(
            filePath,
            filename: filePath.split('/').last,
          ),
      });

      final response = await _dio.put(
        '/api/user/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = _handleResponse(response);
      return UserModel.fromJson(data['user'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.put(
        '/api/user/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all transactions
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _dio.get('/api/transactions');
      final data = _handleResponse(response);
      final list = (data['transactions'] as List?) ?? [];
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get transaction by ID
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final response = await _dio.get('/api/transactions/$id');
      final data = _handleResponse(response);
      return TransactionModel.fromJson(data['transaction'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new transaction
  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/transactions', data: data);
      final responseData = _handleResponse(response);
      return TransactionModel.fromJson(
        responseData['transaction'] ?? responseData,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update transaction
  Future<TransactionModel> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/api/transactions/$id', data: data);
      final responseData = _handleResponse(response);
      return TransactionModel.fromJson(
        responseData['transaction'] ?? responseData,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/api/transactions/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all goals
  Future<List<GoalModel>> getGoals() async {
    try {
      final response = await _dio.get('/api/goals');
      final data = _handleResponse(response);
      final list = (data['goals'] as List?) ?? [];
      return list.map((e) => GoalModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get goal by ID
  Future<GoalModel> getGoalById(String id) async {
    try {
      final response = await _dio.get('/api/goals/$id');
      final data = _handleResponse(response);
      return GoalModel.fromJson(data['goal'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create new goal
  Future<GoalModel> createGoal(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/goals', data: data);
      final responseData = _handleResponse(response);
      return GoalModel.fromJson(responseData['goal'] ?? responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update goal
  Future<GoalModel> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/goals/$id', data: data);
      final responseData = _handleResponse(response);
      return GoalModel.fromJson(responseData['goal'] ?? responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Add progress to goal (tambah tabungan)
  Future<GoalModel> addGoalProgress(String id, double amount) async {
    try {
      final response = await _dio.post(
        '/api/goals/$id/add',
        data: {'amount': amount},
      );
      final data = _handleResponse(response);
      return GoalModel.fromJson(data['goal'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Withdraw from goal (tarik dana)
  Future<GoalModel> withdrawGoal(String id, double amount) async {
    try {
      final response = await _dio.post(
        '/api/goals/$id/withdraw',
        data: {'amount': amount},
      );
      final data = _handleResponse(response);
      return GoalModel.fromJson(data['goal'] ?? data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete goal
  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('/api/goals/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get financial summary
  Future<SummaryModel> getSummary() async {
    try {
      final response = await _dio.get('/api/stats/summary');
      return SummaryModel.fromJson(_handleResponse(response));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get expense by category
  Future<List<CategoryExpense>> getExpenseByCategory() async {
    try {
      final response = await _dio.get('/api/stats/expense-by-category');
      final data = _handleResponse(response);
      final list = (data['categories'] as List?) ?? [];
      return list.map((e) => CategoryExpense.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get income vs pengeluaran
  Future<Map<String, dynamic>> getIncomeVsExpense() async {
    try {
      final response = await _dio.get('/api/stats/income-vs-expense');
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/api/categories');
      final data = _handleResponse(response);
      final list = (data['categories'] as List?) ?? [];
      return list.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

/// Custom exception untuk API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}
