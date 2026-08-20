// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_database_io.dart';

// ignore_for_file: type=lint
class $CachedProductsTable extends CachedProducts
    with TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _salePriceMeta =
      const VerificationMeta('salePrice');
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
      'sale_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentStockMeta =
      const VerificationMeta('currentStock');
  @override
  late final GeneratedColumn<double> currentStock = GeneratedColumn<double>(
      'current_stock', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lowStockLimitMeta =
      const VerificationMeta('lowStockLimit');
  @override
  late final GeneratedColumn<double> lowStockLimit = GeneratedColumn<double>(
      'low_stock_limit', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'));
  static const VerificationMeta _photoThumbUrlMeta =
      const VerificationMeta('photoThumbUrl');
  @override
  late final GeneratedColumn<String> photoThumbUrl = GeneratedColumn<String>(
      'photo_thumb_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        salePrice,
        currentStock,
        lowStockLimit,
        isActive,
        photoThumbUrl,
        company,
        category,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_products';
  @override
  VerificationContext validateIntegrity(Insertable<CachedProduct> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sale_price')) {
      context.handle(_salePriceMeta,
          salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta));
    } else if (isInserting) {
      context.missing(_salePriceMeta);
    }
    if (data.containsKey('current_stock')) {
      context.handle(
          _currentStockMeta,
          currentStock.isAcceptableOrUnknown(
              data['current_stock']!, _currentStockMeta));
    } else if (isInserting) {
      context.missing(_currentStockMeta);
    }
    if (data.containsKey('low_stock_limit')) {
      context.handle(
          _lowStockLimitMeta,
          lowStockLimit.isAcceptableOrUnknown(
              data['low_stock_limit']!, _lowStockLimitMeta));
    } else if (isInserting) {
      context.missing(_lowStockLimitMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('photo_thumb_url')) {
      context.handle(
          _photoThumbUrlMeta,
          photoThumbUrl.isAcceptableOrUnknown(
              data['photo_thumb_url']!, _photoThumbUrlMeta));
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProduct(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      salePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sale_price'])!,
      currentStock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_stock'])!,
      lowStockLimit: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}low_stock_limit'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      photoThumbUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_thumb_url']),
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
}

class CachedProduct extends DataClass implements Insertable<CachedProduct> {
  final String id;
  final String name;
  final double salePrice;
  final double currentStock;
  final double lowStockLimit;
  final bool isActive;
  final String? photoThumbUrl;
  final String? company;
  final String? category;
  final DateTime updatedAt;
  const CachedProduct(
      {required this.id,
      required this.name,
      required this.salePrice,
      required this.currentStock,
      required this.lowStockLimit,
      required this.isActive,
      this.photoThumbUrl,
      this.company,
      this.category,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sale_price'] = Variable<double>(salePrice);
    map['current_stock'] = Variable<double>(currentStock);
    map['low_stock_limit'] = Variable<double>(lowStockLimit);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || photoThumbUrl != null) {
      map['photo_thumb_url'] = Variable<String>(photoThumbUrl);
    }
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedProductsCompanion(
      id: Value(id),
      name: Value(name),
      salePrice: Value(salePrice),
      currentStock: Value(currentStock),
      lowStockLimit: Value(lowStockLimit),
      isActive: Value(isActive),
      photoThumbUrl: photoThumbUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoThumbUrl),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedProduct.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProduct(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      salePrice: serializer.fromJson<double>(json['salePrice']),
      currentStock: serializer.fromJson<double>(json['currentStock']),
      lowStockLimit: serializer.fromJson<double>(json['lowStockLimit']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      photoThumbUrl: serializer.fromJson<String?>(json['photoThumbUrl']),
      company: serializer.fromJson<String?>(json['company']),
      category: serializer.fromJson<String?>(json['category']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'salePrice': serializer.toJson<double>(salePrice),
      'currentStock': serializer.toJson<double>(currentStock),
      'lowStockLimit': serializer.toJson<double>(lowStockLimit),
      'isActive': serializer.toJson<bool>(isActive),
      'photoThumbUrl': serializer.toJson<String?>(photoThumbUrl),
      'company': serializer.toJson<String?>(company),
      'category': serializer.toJson<String?>(category),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedProduct copyWith(
          {String? id,
          String? name,
          double? salePrice,
          double? currentStock,
          double? lowStockLimit,
          bool? isActive,
          Value<String?> photoThumbUrl = const Value.absent(),
          Value<String?> company = const Value.absent(),
          Value<String?> category = const Value.absent(),
          DateTime? updatedAt}) =>
      CachedProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        salePrice: salePrice ?? this.salePrice,
        currentStock: currentStock ?? this.currentStock,
        lowStockLimit: lowStockLimit ?? this.lowStockLimit,
        isActive: isActive ?? this.isActive,
        photoThumbUrl:
            photoThumbUrl.present ? photoThumbUrl.value : this.photoThumbUrl,
        company: company.present ? company.value : this.company,
        category: category.present ? category.value : this.category,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CachedProduct copyWithCompanion(CachedProductsCompanion data) {
    return CachedProduct(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      currentStock: data.currentStock.present
          ? data.currentStock.value
          : this.currentStock,
      lowStockLimit: data.lowStockLimit.present
          ? data.lowStockLimit.value
          : this.lowStockLimit,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      photoThumbUrl: data.photoThumbUrl.present
          ? data.photoThumbUrl.value
          : this.photoThumbUrl,
      company: data.company.present ? data.company.value : this.company,
      category: data.category.present ? data.category.value : this.category,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProduct(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('salePrice: $salePrice, ')
          ..write('currentStock: $currentStock, ')
          ..write('lowStockLimit: $lowStockLimit, ')
          ..write('isActive: $isActive, ')
          ..write('photoThumbUrl: $photoThumbUrl, ')
          ..write('company: $company, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, salePrice, currentStock,
      lowStockLimit, isActive, photoThumbUrl, company, category, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProduct &&
          other.id == this.id &&
          other.name == this.name &&
          other.salePrice == this.salePrice &&
          other.currentStock == this.currentStock &&
          other.lowStockLimit == this.lowStockLimit &&
          other.isActive == this.isActive &&
          other.photoThumbUrl == this.photoThumbUrl &&
          other.company == this.company &&
          other.category == this.category &&
          other.updatedAt == this.updatedAt);
}

class CachedProductsCompanion extends UpdateCompanion<CachedProduct> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> salePrice;
  final Value<double> currentStock;
  final Value<double> lowStockLimit;
  final Value<bool> isActive;
  final Value<String?> photoThumbUrl;
  final Value<String?> company;
  final Value<String?> category;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.lowStockLimit = const Value.absent(),
    this.isActive = const Value.absent(),
    this.photoThumbUrl = const Value.absent(),
    this.company = const Value.absent(),
    this.category = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProductsCompanion.insert({
    required String id,
    required String name,
    required double salePrice,
    required double currentStock,
    required double lowStockLimit,
    required bool isActive,
    this.photoThumbUrl = const Value.absent(),
    this.company = const Value.absent(),
    this.category = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        salePrice = Value(salePrice),
        currentStock = Value(currentStock),
        lowStockLimit = Value(lowStockLimit),
        isActive = Value(isActive),
        updatedAt = Value(updatedAt);
  static Insertable<CachedProduct> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? salePrice,
    Expression<double>? currentStock,
    Expression<double>? lowStockLimit,
    Expression<bool>? isActive,
    Expression<String>? photoThumbUrl,
    Expression<String>? company,
    Expression<String>? category,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (salePrice != null) 'sale_price': salePrice,
      if (currentStock != null) 'current_stock': currentStock,
      if (lowStockLimit != null) 'low_stock_limit': lowStockLimit,
      if (isActive != null) 'is_active': isActive,
      if (photoThumbUrl != null) 'photo_thumb_url': photoThumbUrl,
      if (company != null) 'company': company,
      if (category != null) 'category': category,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? salePrice,
      Value<double>? currentStock,
      Value<double>? lowStockLimit,
      Value<bool>? isActive,
      Value<String?>? photoThumbUrl,
      Value<String?>? company,
      Value<String?>? category,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CachedProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      salePrice: salePrice ?? this.salePrice,
      currentStock: currentStock ?? this.currentStock,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
      isActive: isActive ?? this.isActive,
      photoThumbUrl: photoThumbUrl ?? this.photoThumbUrl,
      company: company ?? this.company,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<double>(currentStock.value);
    }
    if (lowStockLimit.present) {
      map['low_stock_limit'] = Variable<double>(lowStockLimit.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (photoThumbUrl.present) {
      map['photo_thumb_url'] = Variable<String>(photoThumbUrl.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('salePrice: $salePrice, ')
          ..write('currentStock: $currentStock, ')
          ..write('lowStockLimit: $lowStockLimit, ')
          ..write('isActive: $isActive, ')
          ..write('photoThumbUrl: $photoThumbUrl, ')
          ..write('company: $company, ')
          ..write('category: $category, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingTransactionsTable extends PendingTransactions
    with TableInfo<$PendingTransactionsTable, PendingTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceTxnIdMeta =
      const VerificationMeta('deviceTxnId');
  @override
  late final GeneratedColumn<String> deviceTxnId = GeneratedColumn<String>(
      'device_txn_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _quantityChangeMeta =
      const VerificationMeta('quantityChange');
  @override
  late final GeneratedColumn<double> quantityChange = GeneratedColumn<double>(
      'quantity_change', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        deviceTxnId,
        type,
        productId,
        quantity,
        quantityChange,
        reason,
        createdAt,
        status,
        attemptCount,
        lastError,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<PendingTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_txn_id')) {
      context.handle(
          _deviceTxnIdMeta,
          deviceTxnId.isAcceptableOrUnknown(
              data['device_txn_id']!, _deviceTxnIdMeta));
    } else if (isInserting) {
      context.missing(_deviceTxnIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('quantity_change')) {
      context.handle(
          _quantityChangeMeta,
          quantityChange.isAcceptableOrUnknown(
              data['quantity_change']!, _quantityChangeMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceTxnId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_txn_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity']),
      quantityChange: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity_change']),
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $PendingTransactionsTable createAlias(String alias) {
    return $PendingTransactionsTable(attachedDatabase, alias);
  }
}

class PendingTransaction extends DataClass
    implements Insertable<PendingTransaction> {
  final int id;
  final String deviceTxnId;
  final String type;
  final String productId;
  final double? quantity;
  final double? quantityChange;
  final String? reason;
  final DateTime createdAt;
  final String status;
  final int attemptCount;
  final String? lastError;
  final DateTime? syncedAt;
  const PendingTransaction(
      {required this.id,
      required this.deviceTxnId,
      required this.type,
      required this.productId,
      this.quantity,
      this.quantityChange,
      this.reason,
      required this.createdAt,
      required this.status,
      required this.attemptCount,
      this.lastError,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_txn_id'] = Variable<String>(deviceTxnId);
    map['type'] = Variable<String>(type);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || quantityChange != null) {
      map['quantity_change'] = Variable<double>(quantityChange);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  PendingTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PendingTransactionsCompanion(
      id: Value(id),
      deviceTxnId: Value(deviceTxnId),
      type: Value(type),
      productId: Value(productId),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      quantityChange: quantityChange == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityChange),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      createdAt: Value(createdAt),
      status: Value(status),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory PendingTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingTransaction(
      id: serializer.fromJson<int>(json['id']),
      deviceTxnId: serializer.fromJson<String>(json['deviceTxnId']),
      type: serializer.fromJson<String>(json['type']),
      productId: serializer.fromJson<String>(json['productId']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      quantityChange: serializer.fromJson<double?>(json['quantityChange']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceTxnId': serializer.toJson<String>(deviceTxnId),
      'type': serializer.toJson<String>(type),
      'productId': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<double?>(quantity),
      'quantityChange': serializer.toJson<double?>(quantityChange),
      'reason': serializer.toJson<String?>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  PendingTransaction copyWith(
          {int? id,
          String? deviceTxnId,
          String? type,
          String? productId,
          Value<double?> quantity = const Value.absent(),
          Value<double?> quantityChange = const Value.absent(),
          Value<String?> reason = const Value.absent(),
          DateTime? createdAt,
          String? status,
          int? attemptCount,
          Value<String?> lastError = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      PendingTransaction(
        id: id ?? this.id,
        deviceTxnId: deviceTxnId ?? this.deviceTxnId,
        type: type ?? this.type,
        productId: productId ?? this.productId,
        quantity: quantity.present ? quantity.value : this.quantity,
        quantityChange:
            quantityChange.present ? quantityChange.value : this.quantityChange,
        reason: reason.present ? reason.value : this.reason,
        createdAt: createdAt ?? this.createdAt,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: lastError.present ? lastError.value : this.lastError,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  PendingTransaction copyWithCompanion(PendingTransactionsCompanion data) {
    return PendingTransaction(
      id: data.id.present ? data.id.value : this.id,
      deviceTxnId:
          data.deviceTxnId.present ? data.deviceTxnId.value : this.deviceTxnId,
      type: data.type.present ? data.type.value : this.type,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityChange: data.quantityChange.present
          ? data.quantityChange.value
          : this.quantityChange,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransaction(')
          ..write('id: $id, ')
          ..write('deviceTxnId: $deviceTxnId, ')
          ..write('type: $type, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('quantityChange: $quantityChange, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      deviceTxnId,
      type,
      productId,
      quantity,
      quantityChange,
      reason,
      createdAt,
      status,
      attemptCount,
      lastError,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingTransaction &&
          other.id == this.id &&
          other.deviceTxnId == this.deviceTxnId &&
          other.type == this.type &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.quantityChange == this.quantityChange &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.syncedAt == this.syncedAt);
}

class PendingTransactionsCompanion extends UpdateCompanion<PendingTransaction> {
  final Value<int> id;
  final Value<String> deviceTxnId;
  final Value<String> type;
  final Value<String> productId;
  final Value<double?> quantity;
  final Value<double?> quantityChange;
  final Value<String?> reason;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime?> syncedAt;
  const PendingTransactionsCompanion({
    this.id = const Value.absent(),
    this.deviceTxnId = const Value.absent(),
    this.type = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityChange = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  PendingTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceTxnId,
    required String type,
    required String productId,
    this.quantity = const Value.absent(),
    this.quantityChange = const Value.absent(),
    this.reason = const Value.absent(),
    required DateTime createdAt,
    required String status,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.syncedAt = const Value.absent(),
  })  : deviceTxnId = Value(deviceTxnId),
        type = Value(type),
        productId = Value(productId),
        createdAt = Value(createdAt),
        status = Value(status);
  static Insertable<PendingTransaction> custom({
    Expression<int>? id,
    Expression<String>? deviceTxnId,
    Expression<String>? type,
    Expression<String>? productId,
    Expression<double>? quantity,
    Expression<double>? quantityChange,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceTxnId != null) 'device_txn_id': deviceTxnId,
      if (type != null) 'type': type,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (quantityChange != null) 'quantity_change': quantityChange,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  PendingTransactionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceTxnId,
      Value<String>? type,
      Value<String>? productId,
      Value<double?>? quantity,
      Value<double?>? quantityChange,
      Value<String?>? reason,
      Value<DateTime>? createdAt,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<String?>? lastError,
      Value<DateTime?>? syncedAt}) {
    return PendingTransactionsCompanion(
      id: id ?? this.id,
      deviceTxnId: deviceTxnId ?? this.deviceTxnId,
      type: type ?? this.type,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      quantityChange: quantityChange ?? this.quantityChange,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceTxnId.present) {
      map['device_txn_id'] = Variable<String>(deviceTxnId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (quantityChange.present) {
      map['quantity_change'] = Variable<double>(quantityChange.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('deviceTxnId: $deviceTxnId, ')
          ..write('type: $type, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('quantityChange: $quantityChange, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _lastProductSyncAtMeta =
      const VerificationMeta('lastProductSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastProductSyncAt =
      GeneratedColumn<DateTime>('last_product_sync_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>('last_successful_sync_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, lastProductSyncAt, lastSuccessfulSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_product_sync_at')) {
      context.handle(
          _lastProductSyncAtMeta,
          lastProductSyncAt.isAcceptableOrUnknown(
              data['last_product_sync_at']!, _lastProductSyncAtMeta));
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
          _lastSuccessfulSyncAtMeta,
          lastSuccessfulSyncAt.isAcceptableOrUnknown(
              data['last_successful_sync_at']!, _lastSuccessfulSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lastProductSyncAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_product_sync_at']),
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_successful_sync_at']),
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataData extends DataClass
    implements Insertable<SyncMetadataData> {
  final int id;
  final DateTime? lastProductSyncAt;
  final DateTime? lastSuccessfulSyncAt;
  const SyncMetadataData(
      {required this.id, this.lastProductSyncAt, this.lastSuccessfulSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lastProductSyncAt != null) {
      map['last_product_sync_at'] = Variable<DateTime>(lastProductSyncAt);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      id: Value(id),
      lastProductSyncAt: lastProductSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProductSyncAt),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
    );
  }

  factory SyncMetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataData(
      id: serializer.fromJson<int>(json['id']),
      lastProductSyncAt:
          serializer.fromJson<DateTime?>(json['lastProductSyncAt']),
      lastSuccessfulSyncAt:
          serializer.fromJson<DateTime?>(json['lastSuccessfulSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastProductSyncAt': serializer.toJson<DateTime?>(lastProductSyncAt),
      'lastSuccessfulSyncAt':
          serializer.toJson<DateTime?>(lastSuccessfulSyncAt),
    };
  }

  SyncMetadataData copyWith(
          {int? id,
          Value<DateTime?> lastProductSyncAt = const Value.absent(),
          Value<DateTime?> lastSuccessfulSyncAt = const Value.absent()}) =>
      SyncMetadataData(
        id: id ?? this.id,
        lastProductSyncAt: lastProductSyncAt.present
            ? lastProductSyncAt.value
            : this.lastProductSyncAt,
        lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
            ? lastSuccessfulSyncAt.value
            : this.lastSuccessfulSyncAt,
      );
  SyncMetadataData copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataData(
      id: data.id.present ? data.id.value : this.id,
      lastProductSyncAt: data.lastProductSyncAt.present
          ? data.lastProductSyncAt.value
          : this.lastProductSyncAt,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataData(')
          ..write('id: $id, ')
          ..write('lastProductSyncAt: $lastProductSyncAt, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastProductSyncAt, lastSuccessfulSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataData &&
          other.id == this.id &&
          other.lastProductSyncAt == this.lastProductSyncAt &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataData> {
  final Value<int> id;
  final Value<DateTime?> lastProductSyncAt;
  final Value<DateTime?> lastSuccessfulSyncAt;
  const SyncMetadataCompanion({
    this.id = const Value.absent(),
    this.lastProductSyncAt = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    this.id = const Value.absent(),
    this.lastProductSyncAt = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
  });
  static Insertable<SyncMetadataData> custom({
    Expression<int>? id,
    Expression<DateTime>? lastProductSyncAt,
    Expression<DateTime>? lastSuccessfulSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastProductSyncAt != null) 'last_product_sync_at': lastProductSyncAt,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
    });
  }

  SyncMetadataCompanion copyWith(
      {Value<int>? id,
      Value<DateTime?>? lastProductSyncAt,
      Value<DateTime?>? lastSuccessfulSyncAt}) {
    return SyncMetadataCompanion(
      id: id ?? this.id,
      lastProductSyncAt: lastProductSyncAt ?? this.lastProductSyncAt,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastProductSyncAt.present) {
      map['last_product_sync_at'] = Variable<DateTime>(lastProductSyncAt.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] =
          Variable<DateTime>(lastSuccessfulSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('id: $id, ')
          ..write('lastProductSyncAt: $lastProductSyncAt, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncDatabase extends GeneratedDatabase {
  _$SyncDatabase(QueryExecutor e) : super(e);
  $SyncDatabaseManager get managers => $SyncDatabaseManager(this);
  late final $CachedProductsTable cachedProducts = $CachedProductsTable(this);
  late final $PendingTransactionsTable pendingTransactions =
      $PendingTransactionsTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedProducts, pendingTransactions, syncMetadata];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CachedProductsTableCreateCompanionBuilder = CachedProductsCompanion
    Function({
  required String id,
  required String name,
  required double salePrice,
  required double currentStock,
  required double lowStockLimit,
  required bool isActive,
  Value<String?> photoThumbUrl,
  Value<String?> company,
  Value<String?> category,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CachedProductsTableUpdateCompanionBuilder = CachedProductsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<double> salePrice,
  Value<double> currentStock,
  Value<double> lowStockLimit,
  Value<bool> isActive,
  Value<String?> photoThumbUrl,
  Value<String?> company,
  Value<String?> category,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CachedProductsTableFilterComposer
    extends Composer<_$SyncDatabase, $CachedProductsTable> {
  $$CachedProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salePrice => $composableBuilder(
      column: $table.salePrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentStock => $composableBuilder(
      column: $table.currentStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lowStockLimit => $composableBuilder(
      column: $table.lowStockLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoThumbUrl => $composableBuilder(
      column: $table.photoThumbUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedProductsTableOrderingComposer
    extends Composer<_$SyncDatabase, $CachedProductsTable> {
  $$CachedProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salePrice => $composableBuilder(
      column: $table.salePrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentStock => $composableBuilder(
      column: $table.currentStock,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lowStockLimit => $composableBuilder(
      column: $table.lowStockLimit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoThumbUrl => $composableBuilder(
      column: $table.photoThumbUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedProductsTableAnnotationComposer
    extends Composer<_$SyncDatabase, $CachedProductsTable> {
  $$CachedProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<double> get currentStock => $composableBuilder(
      column: $table.currentStock, builder: (column) => column);

  GeneratedColumn<double> get lowStockLimit => $composableBuilder(
      column: $table.lowStockLimit, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get photoThumbUrl => $composableBuilder(
      column: $table.photoThumbUrl, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedProductsTableTableManager extends RootTableManager<
    _$SyncDatabase,
    $CachedProductsTable,
    CachedProduct,
    $$CachedProductsTableFilterComposer,
    $$CachedProductsTableOrderingComposer,
    $$CachedProductsTableAnnotationComposer,
    $$CachedProductsTableCreateCompanionBuilder,
    $$CachedProductsTableUpdateCompanionBuilder,
    (
      CachedProduct,
      BaseReferences<_$SyncDatabase, $CachedProductsTable, CachedProduct>
    ),
    CachedProduct,
    PrefetchHooks Function()> {
  $$CachedProductsTableTableManager(
      _$SyncDatabase db, $CachedProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> salePrice = const Value.absent(),
            Value<double> currentStock = const Value.absent(),
            Value<double> lowStockLimit = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> photoThumbUrl = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedProductsCompanion(
            id: id,
            name: name,
            salePrice: salePrice,
            currentStock: currentStock,
            lowStockLimit: lowStockLimit,
            isActive: isActive,
            photoThumbUrl: photoThumbUrl,
            company: company,
            category: category,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required double salePrice,
            required double currentStock,
            required double lowStockLimit,
            required bool isActive,
            Value<String?> photoThumbUrl = const Value.absent(),
            Value<String?> company = const Value.absent(),
            Value<String?> category = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedProductsCompanion.insert(
            id: id,
            name: name,
            salePrice: salePrice,
            currentStock: currentStock,
            lowStockLimit: lowStockLimit,
            isActive: isActive,
            photoThumbUrl: photoThumbUrl,
            company: company,
            category: category,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedProductsTableProcessedTableManager = ProcessedTableManager<
    _$SyncDatabase,
    $CachedProductsTable,
    CachedProduct,
    $$CachedProductsTableFilterComposer,
    $$CachedProductsTableOrderingComposer,
    $$CachedProductsTableAnnotationComposer,
    $$CachedProductsTableCreateCompanionBuilder,
    $$CachedProductsTableUpdateCompanionBuilder,
    (
      CachedProduct,
      BaseReferences<_$SyncDatabase, $CachedProductsTable, CachedProduct>
    ),
    CachedProduct,
    PrefetchHooks Function()>;
typedef $$PendingTransactionsTableCreateCompanionBuilder
    = PendingTransactionsCompanion Function({
  Value<int> id,
  required String deviceTxnId,
  required String type,
  required String productId,
  Value<double?> quantity,
  Value<double?> quantityChange,
  Value<String?> reason,
  required DateTime createdAt,
  required String status,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<DateTime?> syncedAt,
});
typedef $$PendingTransactionsTableUpdateCompanionBuilder
    = PendingTransactionsCompanion Function({
  Value<int> id,
  Value<String> deviceTxnId,
  Value<String> type,
  Value<String> productId,
  Value<double?> quantity,
  Value<double?> quantityChange,
  Value<String?> reason,
  Value<DateTime> createdAt,
  Value<String> status,
  Value<int> attemptCount,
  Value<String?> lastError,
  Value<DateTime?> syncedAt,
});

class $$PendingTransactionsTableFilterComposer
    extends Composer<_$SyncDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceTxnId => $composableBuilder(
      column: $table.deviceTxnId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantityChange => $composableBuilder(
      column: $table.quantityChange,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$PendingTransactionsTableOrderingComposer
    extends Composer<_$SyncDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceTxnId => $composableBuilder(
      column: $table.deviceTxnId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantityChange => $composableBuilder(
      column: $table.quantityChange,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingTransactionsTableAnnotationComposer
    extends Composer<_$SyncDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceTxnId => $composableBuilder(
      column: $table.deviceTxnId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get quantityChange => $composableBuilder(
      column: $table.quantityChange, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$PendingTransactionsTableTableManager extends RootTableManager<
    _$SyncDatabase,
    $PendingTransactionsTable,
    PendingTransaction,
    $$PendingTransactionsTableFilterComposer,
    $$PendingTransactionsTableOrderingComposer,
    $$PendingTransactionsTableAnnotationComposer,
    $$PendingTransactionsTableCreateCompanionBuilder,
    $$PendingTransactionsTableUpdateCompanionBuilder,
    (
      PendingTransaction,
      BaseReferences<_$SyncDatabase, $PendingTransactionsTable,
          PendingTransaction>
    ),
    PendingTransaction,
    PrefetchHooks Function()> {
  $$PendingTransactionsTableTableManager(
      _$SyncDatabase db, $PendingTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceTxnId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double?> quantity = const Value.absent(),
            Value<double?> quantityChange = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              PendingTransactionsCompanion(
            id: id,
            deviceTxnId: deviceTxnId,
            type: type,
            productId: productId,
            quantity: quantity,
            quantityChange: quantityChange,
            reason: reason,
            createdAt: createdAt,
            status: status,
            attemptCount: attemptCount,
            lastError: lastError,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceTxnId,
            required String type,
            required String productId,
            Value<double?> quantity = const Value.absent(),
            Value<double?> quantityChange = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            required DateTime createdAt,
            required String status,
            Value<int> attemptCount = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
          }) =>
              PendingTransactionsCompanion.insert(
            id: id,
            deviceTxnId: deviceTxnId,
            type: type,
            productId: productId,
            quantity: quantity,
            quantityChange: quantityChange,
            reason: reason,
            createdAt: createdAt,
            status: status,
            attemptCount: attemptCount,
            lastError: lastError,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$SyncDatabase,
    $PendingTransactionsTable,
    PendingTransaction,
    $$PendingTransactionsTableFilterComposer,
    $$PendingTransactionsTableOrderingComposer,
    $$PendingTransactionsTableAnnotationComposer,
    $$PendingTransactionsTableCreateCompanionBuilder,
    $$PendingTransactionsTableUpdateCompanionBuilder,
    (
      PendingTransaction,
      BaseReferences<_$SyncDatabase, $PendingTransactionsTable,
          PendingTransaction>
    ),
    PendingTransaction,
    PrefetchHooks Function()>;
typedef $$SyncMetadataTableCreateCompanionBuilder = SyncMetadataCompanion
    Function({
  Value<int> id,
  Value<DateTime?> lastProductSyncAt,
  Value<DateTime?> lastSuccessfulSyncAt,
});
typedef $$SyncMetadataTableUpdateCompanionBuilder = SyncMetadataCompanion
    Function({
  Value<int> id,
  Value<DateTime?> lastProductSyncAt,
  Value<DateTime?> lastSuccessfulSyncAt,
});

class $$SyncMetadataTableFilterComposer
    extends Composer<_$SyncDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastProductSyncAt => $composableBuilder(
      column: $table.lastProductSyncAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
      column: $table.lastSuccessfulSyncAt,
      builder: (column) => ColumnFilters(column));
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$SyncDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastProductSyncAt => $composableBuilder(
      column: $table.lastProductSyncAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
      column: $table.lastSuccessfulSyncAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$SyncDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get lastProductSyncAt => $composableBuilder(
      column: $table.lastProductSyncAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
      column: $table.lastSuccessfulSyncAt, builder: (column) => column);
}

class $$SyncMetadataTableTableManager extends RootTableManager<
    _$SyncDatabase,
    $SyncMetadataTable,
    SyncMetadataData,
    $$SyncMetadataTableFilterComposer,
    $$SyncMetadataTableOrderingComposer,
    $$SyncMetadataTableAnnotationComposer,
    $$SyncMetadataTableCreateCompanionBuilder,
    $$SyncMetadataTableUpdateCompanionBuilder,
    (
      SyncMetadataData,
      BaseReferences<_$SyncDatabase, $SyncMetadataTable, SyncMetadataData>
    ),
    SyncMetadataData,
    PrefetchHooks Function()> {
  $$SyncMetadataTableTableManager(_$SyncDatabase db, $SyncMetadataTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> lastProductSyncAt = const Value.absent(),
            Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
          }) =>
              SyncMetadataCompanion(
            id: id,
            lastProductSyncAt: lastProductSyncAt,
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime?> lastProductSyncAt = const Value.absent(),
            Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
          }) =>
              SyncMetadataCompanion.insert(
            id: id,
            lastProductSyncAt: lastProductSyncAt,
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetadataTableProcessedTableManager = ProcessedTableManager<
    _$SyncDatabase,
    $SyncMetadataTable,
    SyncMetadataData,
    $$SyncMetadataTableFilterComposer,
    $$SyncMetadataTableOrderingComposer,
    $$SyncMetadataTableAnnotationComposer,
    $$SyncMetadataTableCreateCompanionBuilder,
    $$SyncMetadataTableUpdateCompanionBuilder,
    (
      SyncMetadataData,
      BaseReferences<_$SyncDatabase, $SyncMetadataTable, SyncMetadataData>
    ),
    SyncMetadataData,
    PrefetchHooks Function()>;

class $SyncDatabaseManager {
  final _$SyncDatabase _db;
  $SyncDatabaseManager(this._db);
  $$CachedProductsTableTableManager get cachedProducts =>
      $$CachedProductsTableTableManager(_db, _db.cachedProducts);
  $$PendingTransactionsTableTableManager get pendingTransactions =>
      $$PendingTransactionsTableTableManager(_db, _db.pendingTransactions);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
}
