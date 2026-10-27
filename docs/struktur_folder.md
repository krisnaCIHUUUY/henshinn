lib/
├── main.dart
├── app.dart                          # MaterialApp, tema, routing awal
│
├── core/                             # Kode yang dipakai lintas fitur
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── database/
│   │   ├── app_database.dart         # instance drift database
│   │   ├── tables/                   # definisi tabel drift
│   │   │   ├── products_table.dart
│   │   │   ├── categories_table.dart
│   │   │   ├── transactions_table.dart
│   │   │   ├── transaction_items_table.dart
│   │   │   └── stock_movements_table.dart
│   │   └── daos/                     # data access objects
│   │       ├── product_dao.dart
│   │       ├── transaction_dao.dart
│   │       └── report_dao.dart
│   ├── errors/
│   │   └── failures.dart
│   ├── router/
│   │   └── app_router.dart           # go_router config
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── currency_formatter.dart
│       └── date_formatter.dart
│
├── features/
│   ├── product/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── product_model.dart
│   │   │   └── repositories/
│   │   │       └── product_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── product.dart
│   │   │   ├── repositories/
│   │   │   │   └── product_repository.dart      # interface (abstract)
│   │   │   └── usecases/
│   │   │       ├── get_products.dart
│   │   │       ├── add_product.dart
│   │   │       ├── update_product.dart
│   │   │       └── delete_product.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── product_provider.dart         # riverpod
│   │       ├── screens/
│   │       │   ├── product_list_screen.dart
│   │       │   └── product_form_screen.dart
│   │       └── widgets/
│   │           ├── product_card.dart
│   │           └── product_search_bar.dart
│   │
│   ├── transaction/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── transaction_model.dart
│   │   │   └── repositories/
│   │   │       └── transaction_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── transaction.dart
│   │   │   │   └── cart_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── transaction_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_transaction.dart
│   │   │       ├── void_transaction.dart
│   │   │       └── get_transaction_history.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── cart_provider.dart
│   │       │   └── transaction_provider.dart
│   │       ├── screens/
│   │       │   ├── cashier_screen.dart
│   │       │   ├── payment_screen.dart
│   │       │   └── transaction_history_screen.dart
│   │       └── widgets/
│   │           ├── cart_list.dart
│   │           └── numpad_widget.dart
│   │
│   ├── report/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── report_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── report_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_daily_sales.dart
│   │   │       └── get_best_sellers.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── report_provider.dart
│   │       ├── screens/
│   │       │   └── report_screen.dart
│   │       └── widgets/
│   │           └── sales_chart.dart
│   │
│   ├── backup/                       # export/import database
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── backup_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── backup_repository.dart
│   │   │   └── usecases/
│   │   │       ├── export_backup.dart
│   │   │       └── import_backup.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── backup_provider.dart
│   │       └── screens/
│   │           └── backup_screen.dart
│   │
│   └── printer/
│       ├── data/
│       │   └── repositories/
│       │       └── printer_repository_impl.dart
│       ├── domain/
│       │   ├── repositories/
│       │   │   └── printer_repository.dart
│       │   └── usecases/
│       │       └── print_receipt.dart
│       └── presentation/
│           ├── providers/
│           │   └── printer_provider.dart
│           └── screens/
│               └── printer_setup_screen.dart
│
└── shared/                           # widget/komponen reusable lintas fitur
    ├── widgets/
    │   ├── app_button.dart
    │   ├── app_text_field.dart
    │   ├── empty_state.dart
    │   └── loading_indicator.dart
    └── extensions/
        └── context_extensions.dart