-- import: ${dp.name}
-- 1行 = 1ロード単位。split_from / split_to の2カラムを返すこと
${dp.split_list_query.split('__CATALOG__').join(zc.catalog)}
