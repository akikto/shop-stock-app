/// Bengali-first UI strings for Product Management.
///
/// Kept as a small, explicit map rather than a full intl/ARB pipeline
/// for Phase 1 — that stays proportionate to "Bengali-first labels for
/// this form and these screens" and avoids pulling in a translation
/// framework before there's more than one feature area to localize.
/// English appears as secondary text where useful, per spec, rather
/// than as a separate switchable locale in Phase 1.
class AppStrings {
  const AppStrings._();

  // Product form
  static const addProduct = 'পণ্য যোগ করুন';
  static const editProduct = 'পণ্য সম্পাদনা';
  static const productName = 'পণ্যের নাম';
  static const company = 'কোম্পানি';
  static const category = 'ক্যাটাগরি';
  static const packSize = 'প্যাক সাইজ';
  static const mrp = 'MRP';
  static const purchasePrice = 'ক্রয় মূল্য';
  static const salePrice = 'বিক্রয় মূল্য';
  static const lowStockLimit = 'কম স্টক সীমা';
  static const save = 'সংরক্ষণ করুন';
  static const update = 'পরিবর্তন করুন';
  static const deactivate = 'নিষ্ক্রিয় করুন';
  static const cancel = 'বাতিল';

  // Photo picker
  static const addPhoto = 'ছবি যোগ করুন';
  static const changePhoto = 'ছবি পরিবর্তন করুন';
  static const takePhoto = 'ক্যামেরা দিয়ে তুলুন';
  static const chooseFromGallery = 'গ্যালারি থেকে বাছাই করুন';
  static const removePhoto = 'ছবি সরান';

  // Product list / search
  static const products = 'পণ্যসমূহ';
  static const searchProducts = 'পণ্য খুঁজুন';
  static const noProductsFound = 'কোনো পণ্য পাওয়া যায়নি';
  static const currentStock = 'বর্তমান স্টক';
  static const lowStock = 'স্টক কম';

  // Product detail
  static const productDetails = 'পণ্যের বিবরণ';
  static const active = 'সক্রিয়';
  static const inactive = 'নিষ্ক্রিয়';
  static const createdAt = 'তৈরি হয়েছে';
  static const updatedAt = 'হালনাগাদ হয়েছে';
  static const edit = 'সম্পাদনা করুন';

  // Validation messages (Bengali first, English fallback in parentheses
  // is added by the validator, not hardcoded here, to stay reusable)
  static const nameRequired = 'পণ্যের নাম আবশ্যক';
  static const priceInvalid = 'সঠিক মূল্য দিন';
  static const priceNegative = 'মূল্য ঋণাত্মক হতে পারবে না';
  static const lowStockNegative = 'কম স্টক সীমা ঋণাত্মক হতে পারবে না';

  // Generic
  static const confirm = 'নিশ্চিত করুন';
  static const areYouSure = 'আপনি কি নিশ্চিত?';
  static const somethingWentWrong = 'কিছু ভুল হয়েছে';
  static const retry = 'আবার চেষ্টা করুন';
  static const loadMore = 'আরও দেখুন';

  // Sale
  static const sale = 'বিক্রি';
  static const quantity = 'পরিমাণ';
  static const availableStock = 'উপলব্ধ স্টক';
  static const total = 'মোট';
  static const confirmSale = 'বিক্রি নিশ্চিত করুন';
  static const saleSuccessful = 'বিক্রি সম্পন্ন হয়েছে';
  static const insufficientStock = 'পর্যাপ্ত স্টক নেই';
  static const selectProduct = 'পণ্য বাছাই করুন';

  // Stock In / Adjustment
  static const stockIn = 'স্টক যোগ';
  static const stockAdjustment = 'স্টক সমন্বয়';
  static const addStock = 'স্টক যোগ করুন';
  static const adjustStock = 'স্টক সমন্বয় করুন';
  static const reason = 'কারণ';
  static const reasonRequired = 'কারণ আবশ্যক';
  static const stockAddedSuccessfully = 'স্টক যোগ হয়েছে';
  static const stockAdjustedSuccessfully = 'স্টক সমন্বয় হয়েছে';
  static const increaseStock = 'বৃদ্ধি';
  static const decreaseStock = 'হ্রাস';

  // History
  static const history = 'ইতিহাস';
  static const noHistoryFound = 'কোনো ইতিহাস পাওয়া যায়নি';
  static const loadingHistory = 'ইতিহাস লোড হচ্ছে...';
  static const historyLoadFailed = 'ইতিহাস লোড করা যায়নি';
  static const historyConnectionFailed =
      'ইতিহাস লোড করা যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।';
  static const performedBy = 'কর্মী';
  static const actionSale = 'বিক্রি হয়েছে';
  static const actionStockIn = 'স্টক যোগ হয়েছে';
  static const actionStockAdjustment = 'স্টক সমন্বয় হয়েছে';
  static const actionProductCreated = 'পণ্য তৈরি হয়েছে';
  static const actionProductUpdated = 'পণ্য হালনাগাদ হয়েছে';
  static const actionPriceUpdated = 'মূল্য হালনাগাদ হয়েছে';
  static const actionProductDeactivated = 'পণ্য নিষ্ক্রিয় হয়েছে';
  static const actionUserCreated = 'কর্মী যোগ হয়েছে';
  static const actionUserRoleChanged = 'ভূমিকা পরিবর্তন হয়েছে';
  static const actionUserDeactivated = 'কর্মী নিষ্ক্রিয় হয়েছে';

  // Phase 3: Product filtering, expiry/composition, activation
  static const composition = 'উপাদান';
  static const expiryDate = 'মেয়াদ উত্তীর্ণের তারিখ';
  static const notSet = 'নির্ধারিত নয়';
  static const activate = 'সক্রিয় করুন';
  static const activatedSuccessfully = 'পণ্য সক্রিয় হয়েছে';
  static const deactivatedSuccessfully = 'পণ্য নিষ্ক্রিয় হয়েছে';
  static const expired = 'মেয়াদ শেষ';
  static const expiringSoon = 'মেয়াদ শীঘ্রই শেষ';
  static const actionProductActivated = 'পণ্য সক্রিয় হয়েছে';
  static const filterByCategory = 'ক্যাটাগরি অনুযায়ী';

  // Dashboard / Reports (Phase 4)
  static const home = 'হোম';
  static const dashboard = 'ড্যাশবোর্ড';
  static const todaySales = 'আজকের বিক্রি';
  static const totalSales = 'মোট বিক্রি';
  static const salesCount = 'বিক্রির সংখ্যা';
  static const stockInCount = 'স্টক যোগ';
  static const adjustmentCount = 'সমন্বয়';
  static const lowStockProducts = 'কম স্টক পণ্য';
  static const mySalesToday = 'আমার আজকের বিক্রি';
  static const reports = 'রিপোর্ট';
  static const staffWiseSales = 'কর্মী অনুযায়ী বিক্রি';
  static const productWiseSales = 'পণ্য অনুযায়ী বিক্রি';
  static const dateRange = 'তারিখ';
  static const today = 'আজ';
  static const last7Days = 'গত ৭ দিন';
  static const noReportData = 'এই সময়ে কোনো তথ্য নেই';
  static const notifications = 'বিজ্ঞপ্তি';
  static const noNotifications = 'কোনো বিজ্ঞপ্তি নেই';
  static const markAllRead = 'সব পড়া হয়েছে';
  static const viewReports = 'রিপোর্ট দেখুন';
  static const quickActions = 'দ্রুত কাজ';
  static const totalActivity = 'মোট কার্যক্রম';
  static const currencySymbol = '৳';
  static const activeProductCount = 'সক্রিয় পণ্য';
  static const quickActionNewSale = 'নতুন বিক্রি';
  static const quickActionStockIn = 'স্টক যোগ';
  static const quickActionHistory = 'ইতিহাস';
  static const customDateRange = 'নিজের তারিখ';
  static const pickDateRange = 'তারিখ বাছাই';
  static const invalidDateRange = 'অবৈধ তারিখের পরিসর';
  static const loadingReports = 'রিপোর্ট লোড হচ্ছে...';
  static const dashboardLoadFailed = 'ড্যাশবোর্ড লোড করা যায়নি';
  static const staffReportLoadFailed = 'কর্মী রিপোর্ট লোড করা যায়নি';
  static const productReportLoadFailed = 'পণ্য রিপোর্ট লোড করা যায়নি';
  static const stockMovementReportLoadFailed =
      'স্টক চলাচল রিপোর্ট লোড করা যায়নি';

  static String reportSaleCount(int count) => '$countটি বিক্রি';

  static String reportProductSubtitle(int saleCount, num totalQuantity) =>
      '${reportSaleCount(saleCount)} · ${AppStrings.quantity} $totalQuantity';

  // Phase 5: Offline sync
  static const offlineMode = 'অফলাইন মোড';
  static const savedLocallyWillSync =
      'স্থানীয়ভাবে সংরক্ষিত হয়েছে। অনলাইন হলে সিঙ্ক হবে।';
  static const syncing = 'সিঙ্ক হচ্ছে...';
  static const pendingSync = 'অপেক্ষমান সিঙ্ক';
  static const syncFailed = 'সিঙ্ক ব্যর্থ';
  static const retrySync = 'আবার সিঙ্ক করুন';
  static const staleCachedData = 'সংরক্ষিত তথ্য — স্টক আপডেট নাও হতে পারে';
  static const queuedTransaction = 'অপেক্ষমান লেনদেন';
  static const pendingTransactions = 'অপেক্ষমান লেনদেন';
  static const noCachedProducts =
      'কোনো সংরক্ষিত পণ্য নেই। একবার অনলাইনে থাকলে তালিকা আপডেট হবে।';
  static const deleteFailedTransaction = 'বাতিল করুন';
  static const retryFailedTransaction = 'আবার চেষ্টা';
  static const transactionSynced = 'সিঙ্ক সম্পন্ন';
  static const pendingCountLabel = 'অপেক্ষমান';

  // Phase 6: Staff, notification prefs, reports, sync conflicts
  static const staffManagement = 'কর্মী ব্যবস্থাপনা';
  static const notificationPreferences = 'বিজ্ঞপ্তি পছন্দ';
  static const syncConflicts = 'সিঙ্ক সংঘর্ষ';
  static const stockMovementReport = 'স্টক চলাচল';
  static const noLowStockProducts = 'কোনো কম স্টক পণ্য নেই';
  static const noSyncConflicts = 'কোনো সিঙ্ক সংঘর্ষ নেই';
  static const changeRole = 'ভূমিকা পরিবর্তন';
  static const activateStaff = 'কর্মী সক্রিয় করুন';
  static const deactivateStaff = 'কর্মী নিষ্ক্রিয় করুন';
  static const deactivateStaffConfirm =
      'এই কর্মীকে নিষ্ক্রিয় করলে তারা লগ ইন করতে পারবে না।';
  static const staffUpdated = 'কর্মী তথ্য হালনাগাদ হয়েছে';
  static const notifySales = 'বিক্রি বিজ্ঞপ্তি';
  static const notifyStockIn = 'স্টক যোগ বিজ্ঞপ্তি';
  static const notifyStockAdjustment = 'স্টক সমন্বয় বিজ্ঞপ্তি';
  static const notifyLowStock = 'কম স্টক বিজ্ঞপ্তি';
  static const preferencesSaved = 'পছন্দ সংরক্ষিত হয়েছে';
  static const markResolved = 'সমাধান হয়েছে';
  static const conflictResolved = 'সংঘর্ষ সমাধান হয়েছে';
  static const viewLowStockList = 'কম স্টক তালিকা দেখুন';
  static const movementSale = 'বিক্রি';
  static const movementStockIn = 'স্টক যোগ';
  static const movementAdjustment = 'সমন্বয়';
  static const inviteStaff = 'কর্মী যোগ করুন';
  static const inviteStaffHelp =
      'নতুন কর্মীর ইমেইল ও অস্থায়ী পাসওয়ার্ড দিন। তারা লগ ইন করে কাজ শুরু করতে পারবে।';
  static const staffName = 'কর্মীর নাম';
  static const temporaryPassword = 'অস্থায়ী পাসওয়ার্ড';
  static const passwordTooShort = 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
  static const createStaffAccount = 'অ্যাকাউন্ট তৈরি করুন';
  static const staffInvited = 'কর্মী অ্যাকাউন্ট তৈরি হয়েছে';

  // Auth / Login
  static const appName = 'Shop Stock & Sales';
  static const email = 'ইমেইল';
  static const password = 'পাসওয়ার্ড';
  static const login = 'লগ ইন';
  static const logout = 'লগ আউট';
  static const enterEmail = 'আপনার ইমেইল দিন';
  static const enterPassword = 'আপনার পাসওয়ার্ড দিন';
  static const accountCreatedbyOwner =
      'অ্যাকাউন্ট মালিক তৈরি করেন। প্রবেশ করতে মালিকের সাথে যোগাযোগ করুন।';

  // Settings
  static const settings = 'সেটিংস';
  static const role = 'ভূমিকা';

  // Misc UI
  static const loadingAccount = 'অ্যাকাউন্ট লোড হচ্ছে...';
  static const loadingDashboard = 'ড্যাশবোর্ড লোড হচ্ছে...';
  static const accountDeactivated =
      'আপনার অ্যাকাউন্ট নিষ্ক্রিয় করা হয়েছে। মালিকের সাথে যোগাযোগ করুন।';
  static const checkProductsTab = 'বিস্তারিত দেখতে পণ্য ট্যাব দেখুন';
}
