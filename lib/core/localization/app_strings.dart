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

  // Navigation / screen titles
  static const home = 'হোম';
  static const sale = 'বিক্রয়';
  static const stockIn = 'স্টক';
  static const history = 'ইতিহাস';
  static const settings = 'সেটিংস';

  // Auth / login
  static const appName = 'Shop Stock & Sales';
  static const email = 'ইমেইল';
  static const password = 'পাসওয়ার্ড';
  static const login = 'লগ ইন';
  static const logout = 'লগ আউট';
  static const enterEmail = 'আপনার ইমেইল দিন';
  static const enterPassword = 'আপনার পাসওয়ার্ড দিন';
  static const accountCreatedByOwner =
      'অ্যাকাউন্ট মালিক তৈরি করেন। প্রবেশ করতে মালিকের সাথে যোগাযোগ করুন।';
  static const accountDeactivated =
      'আপনার অ্যাকাউন্ট নিষ্ক্রিয় করা হয়েছে। মালিকের সাথে যোগাযোগ করুন।';
  static const role = 'ভূমিকা';
}
