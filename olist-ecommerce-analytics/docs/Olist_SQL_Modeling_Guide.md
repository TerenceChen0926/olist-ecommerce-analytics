# Olist 电商数据分析项目：SQL 建模学习手册

> 这是项目构建期间保存的学习记录，包含简化示例和早期字段命名。
> 复现时以 `sql/` 中的脚本为准，字段差异见 `docs/data_dictionary.md`。
> 客户表中的 `customer_id` 是订单级客户记录标识；
> 分析跨订单的独立客户应使用 `customer_unique_id`。
> 准时率的卡片与环形图存在待核验的口径差异，详见 `docs/metrics.md`。

## 1. 项目目标

将 9 张原始电商 CSV 表导入 SQL Server，保留原始数据；完成质量检查、清洗建模和关系验证，最终交给 Power BI 做可视化与业务分析。

完整流程：

```text
原始 CSV
  ↓
SQL 原始表（保留，不修改）
  ↓
数据质量检查
  ↓
维度表 + 事实表 + 日期表
  ↓
关系验证与核心指标
  ↓
Power BI 仪表盘与业务洞察
```

## 2. 为什么不直接使用原始表做 Power BI？

原始表存在以下问题：

- 日期、金额、重量等字段最初以文本形式导入；
- 商品类别是葡萄牙语，需要关联英文翻译；
- 文本可能包含空格、空字符串和缺失值；
- 一张订单可能有多件商品、多个支付记录，表之间粒度不同；
- 原始表混合了数据来源字段与分析字段。

因此采用两层结构：

```text
原始表：用于追溯来源，永久保留
清洗模型：用于分析、关联和 Power BI
```

这样即使清洗逻辑写错，也能从原始表重新生成分析表。

## 3. 原始表层：导入了什么？

原始导入表相当于本项目的 staging layer（暂存层），但保留了 CSV 的原始表名。

| 原始表 | 一行代表什么 | 主要用途 |
|---|---|---|
| `olist_customers_dataset` | 一位下单客户记录 | 客户所在地 |
| `olist_sellers_dataset` | 一个卖家 | 卖家所在地 |
| `olist_products_dataset` | 一个商品 | 商品类别、重量、尺寸 |
| `product_category_name_translation` | 一组类别翻译 | 葡语类别转英文 |
| `olist_orders_dataset` | 一个订单 | 订单状态、下单与配送时间 |
| `olist_order_items_dataset` | 一件订单商品 | 商品价格、运费、卖家 |
| `olist_order_payments_dataset` | 一笔支付记录 | 支付方式、分期、支付金额 |
| `olist_order_reviews_dataset` | 一条评价记录 | 评分、评论、评价时间 |
| `olist_geolocation_dataset` | 一个邮编对应的位置记录 | 地理分析的后续扩展 |

原则：原始表不进行 `DELETE`，不修改字段值，也不作为 Power BI 的主要分析表。

## 4. 数据质量检查：先确认数据能不能用

建模前主要完成四类检查。

### 4.1 重复值检查

目标：确认候选主键是否重复。

```sql
SELECT customer_id, COUNT(*) AS duplicate_count
FROM dbo.olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

若没有返回结果，表示 `customer_id` 没有重复。

- `GROUP BY`：按字段分组。
- `COUNT(*)`：统计每组记录数。
- `HAVING`：筛选分组后的结果。

### 4.2 缺失值检查

目标：识别哪些字段需要保留空值、转换或标记。

```sql
SELECT
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)
        AS missing_order_approved_at
FROM dbo.olist_orders_dataset;
```

项目中的典型缺失：

- 部分订单缺少批准、交给物流或签收时间；
- 610 个商品没有类别；
- 很多评价没有标题或正文。

评价没有标题或正文不等于错误。用户可以只打分、不留言，因此评价记录仍然保留。

### 4.3 表间关联检查

目标：确认明细表中的订单、商品、卖家能否在对应表中找到。

```sql
SELECT COUNT(*) AS items_without_product
FROM dbo.olist_order_items_dataset AS i
LEFT JOIN dbo.olist_products_dataset AS p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL;
```

结果为 0，表示每个订单商品都能找到对应商品。

- `LEFT JOIN`：保留左表全部记录。
- `ON`：定义两张表的匹配条件。
- 右表主键为 `NULL`：表示左表记录找不到匹配对象。

### 4.4 业务逻辑检查

例如检查已送达订单是否缺少签收日期：

```sql
SELECT
    SUM(CASE
        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NULL
        THEN 1 ELSE 0
    END) AS delivered_without_delivery_date
FROM dbo.olist_orders_dataset;
```

这类记录不一定删除，而是在后续计算配送时长、准时率时谨慎处理。

## 5. 什么是维度表和事实表？

### 5.1 维度表：描述“谁、什么、在哪里、何时”

维度表保存相对稳定的描述信息，例如客户、卖家、商品和日期。

```text
客户是谁？
商品是什么？
卖家在哪里？
订单发生在什么日期？
```

### 5.2 事实表：记录“发生了什么业务事件”

事实表保存可计数、可汇总的业务事件，例如订单、订单商品、支付和评价。

```text
发生了什么订单？
卖了什么商品？
支付了多少钱？
顾客给了多少评分？
```

## 6. 创建的新维度表

### 6.1 `dim_customers`

粒度：一行代表一个下单客户记录。  
主键：`customer_id`。  
行数：99,441。

示例：

| customer_id | customer_unique_id | customer_zip_code | customer_city | customer_state |
|---|---|---|---|---|
| `00012a...` | `248ff...` | `06273` | osasco | SP |

邮编使用 `nvarchar`，而不是数字，因为 `01037` 等邮编的前导零不能丢失。

```sql
CREATE TABLE dbo.dim_customers (
    customer_id        nvarchar(50) NOT NULL PRIMARY KEY,
    customer_unique_id nvarchar(50) NULL,
    customer_zip_code  nvarchar(10) NULL,
    customer_city      nvarchar(50) NULL,
    customer_state     nvarchar(10) NULL
);
```

### 6.2 `dim_sellers`

粒度：一行代表一个卖家。  
主键：`seller_id`。  
行数：3,095。

| seller_id | seller_zip_code | seller_city | seller_state |
|---|---|---|---|
| `0015a...` | `90800` | santo andre | SP |

### 6.3 `dim_products`

粒度：一行代表一个商品。  
主键：`product_id`。  
行数：32,951。

| product_id | product_category_name | product_category_name_english | product_weight_g | product_length_cm |
|---|---|---|---:|---:|
| `abc...` | perfumaria | perfumery | 300 | 20 |

这里使用 `LEFT JOIN` 连接类别翻译表：

```sql
FROM dbo.olist_products_dataset AS p
LEFT JOIN dbo.product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
```

使用 `COALESCE` 处理类别缺失：

```sql
COALESCE(
    t.product_category_name_english,
    p.product_category_name,
    'Unknown'
)
```

含义：

1. 优先使用英文类别；
2. 如果没有英文翻译，保留葡萄牙语类别；
3. 如果原始类别也没有，标记为 `Unknown`。

### 6.4 `dim_date`

粒度：一行代表一个自然日。  
主键：`date_key`。  
行数：1,314。  
范围：2016-09-04 至 2020-04-09。

| date_key | full_date | calendar_year | calendar_quarter | calendar_month | year_month | iso_week |
|---:|---|---:|---:|---:|---|---:|
| 20160904 | 2016-09-04 | 2016 | 3 | 9 | 2016-09 | 35 |

日期表可以支持按年、季度、月份和周进行趋势分析，也能避免 Power BI 自动日期表带来的混乱。

## 7. 创建的新事实表

### 7.1 `fact_orders`

粒度：一行代表一个订单。  
主键：`order_id`。  
行数：99,441。

| order_id | customer_id | order_status | order_purchase_at | delivery_days | is_on_time |
|---|---|---|---|---:|---:|
| `000102...` | `abc...` | delivered | 2017-09-13 08:59:02 | 7 | 1 |

字段含义：

- `delivery_days`：下单到签收的天数；
- `is_delivered = 1`：订单已送达；
- `is_on_time = 1`：实际签收日不晚于预计送达日；
- `is_on_time = 0`：已送达但延迟；
- `is_on_time = NULL`：取消、未送达或缺少判断所需日期。

### 7.2 `fact_order_items`

粒度：一行代表一个订单中的一件商品。  
复合主键：`order_id + order_item_id`。  
行数：112,650。

| order_id | order_item_id | product_id | seller_id | price | freight_value | total_item_value |
|---|---:|---|---|---:|---:|---:|
| `000102...` | 1 | `prod...` | `sell...` | 58.90 | 13.29 | 72.19 |

金额定义：

- `price`：商品金额；
- `freight_value`：运费；
- `total_item_value`：商品金额加运费。

一个订单可能购买多件商品，所以不能只用 `order_id` 做主键。

### 7.3 `fact_payments`

粒度：一行代表一笔支付记录。  
复合主键：`order_id + payment_sequential`。  
行数：103,886。

| order_id | payment_sequential | payment_type | payment_installments | payment_value |
|---|---:|---|---:|---:|
| `000102...` | 1 | credit_card | 2 | 72.19 |

一个订单可能分多次支付，因此不能只使用 `order_id` 做主键。

`fact_order_items` 和 `fact_payments` 粒度不同，不能直接连接后同时求和，否则会重复计算金额。

### 7.4 `fact_reviews`

粒度：一行代表一条评价记录。  
主键：`review_key`，它是数据库生成的唯一编号。  
行数：99,224。

| review_key | review_id | order_id | review_score | review_created_at |
|---:|---|---|---:|---|
| 1 | `7bc...` | `73fc...` | 4 | 2018-01-18 |

由于原始数据中的 `review_id` 存在重复，因此使用代理主键：

```sql
review_key int IDENTITY(1,1) NOT NULL PRIMARY KEY
```

`IDENTITY(1,1)` 表示从 1 开始，每新增一行自动增加 1。

## 8. 表之间的关系

```text
dim_customers  1 ── * fact_orders
dim_date       1 ── * fact_orders
fact_orders    1 ── * fact_order_items
fact_orders    1 ── * fact_payments
fact_orders    1 ── * fact_reviews
dim_products   1 ── * fact_order_items
dim_sellers    1 ── * fact_order_items
```

`1 ── *` 表示左侧一条记录可以对应右侧多条记录。

例如：

- 一个客户可以下多个订单；
- 一个订单可以包含多件商品；
- 一个订单可以有多笔支付；
- 一个产品可以被多个订单购买。

## 9. 本项目使用的核心 SQL 语法

| 语法 | 用途 | 项目中的例子 |
|---|---|---|
| `CREATE TABLE` | 创建新表 | 创建维度表、事实表 |
| `DROP TABLE IF EXISTS` | 删除旧的清洗表，便于重建 | 重建 `dim_products` |
| `INSERT INTO ... SELECT` | 把清洗后的数据写入新表 | 原始表写入维度或事实表 |
| `PRIMARY KEY` | 保证每行唯一 | `customer_id`、`order_id` |
| `FOREIGN KEY` | 保证表间引用正确 | 订单引用客户 |
| `LEFT JOIN` | 保留左表并匹配右表 | 商品关联类别翻译 |
| `GROUP BY` | 按字段分组 | 检查重复主键 |
| `HAVING` | 筛选聚合后的分组 | `HAVING COUNT(*) > 1` |
| `CASE WHEN` | 条件计算 | 准时送达标记 |
| `COALESCE` | 取第一个非空值 | 英文类别缺失时回退 |
| `NULLIF` | 将指定值转换成 `NULL` | 空字符串转 `NULL` |
| `LTRIM` / `RTRIM` | 清除文本两侧空格 | 清洗城市、类别字段 |
| `TRY_CONVERT` | 安全转换数据类型 | 文本金额转 `decimal` |
| `CAST` | 转换数据类型 | `datetime2` 转 `date` |
| `DATEDIFF` | 计算日期差 | 配送天数 |
| `DATEPART` | 提取日期部分 | 年、季度、月份 |
| `DATEADD` | 日期加减 | 生成连续日期 |
| `WITH` / CTE | 创建临时查询结果集 | 生成日期序列 |
| `UNION ALL` | 合并多个查询结果 | 最终关系验证 |
| `COUNT` / `SUM` / `AVG` | 统计和汇总 | 订单数、销售额、平均评分 |

## 10. 常见清洗表达式

### 10.1 清除空格并把空字符串变成 NULL

```sql
NULLIF(LTRIM(RTRIM(customer_city)), '')
```

执行顺序：

1. `LTRIM` 删除左侧空格；
2. `RTRIM` 删除右侧空格；
3. `NULLIF(..., '')` 将空字符串转换为 `NULL`。

### 10.2 安全地把文本转换为数值

```sql
TRY_CONVERT(decimal(12, 2), price)
```

如果文本无法转换为金额，`TRY_CONVERT` 返回 `NULL`，不会让整个 SQL 语句报错。

### 10.3 计算配送时长

```sql
CASE
    WHEN order_delivered_customer_at >= order_purchase_at
    THEN DATEDIFF(
        DAY,
        order_purchase_at,
        order_delivered_customer_at
    )
    ELSE NULL
END
```

这样可以避免不合理日期产生负数配送天数。

## 11. 最终业务指标

| 指标 | 结果 |
|---|---:|
| 总订单数 | 99,441 |
| 已送达订单 | 96,478 |
| 订单商品明细数 | 112,650 |
| 商品销售额 | 13,591,643.70 |
| 运费 | 2,251,909.54 |
| 商品金额加运费 | 15,843,553.24 |
| 客户实际支付金额 | 16,008,872.12 |
| 平均配送时长 | 12.50 天 |
| 准时送达率 | 91.89% |
| 平均客户评分 | 4.09 / 5 |

指标口径必须区分：

- 商品销售额：`SUM(fact_order_items[price])`；
- 运费：`SUM(fact_order_items[freight_value])`；
- 客户实际支付额：`SUM(fact_payments[payment_value])`。

三者不是同一个概念，不能随意替换。

## 12. 执行 SQL 时的注意事项

SSMS 在没有选中代码时，会执行当前查询窗口中的全部 SQL。旧表被外键引用后，再次执行前面的 `DROP TABLE` 或 `INSERT` 可能产生报错。

因此学习阶段建议：

1. 每次只选中刚新增的代码；
2. 确认选中范围后再点击“执行”；
3. `DROP TABLE IF EXISTS` 只能针对新建的清洗表，不能用于原始表；
4. 执行后立即检查行数、重复主键和孤儿记录；
5. 修改数据库的 SQL 应保存，便于复现整个流程。

## 13. 进入 Power BI 前的最终成果

SQL 阶段已经完成：

- 保留原始数据；
- 完成数据质量检查；
- 创建 4 张维度表；
- 创建 4 张事实表；
- 创建日期维度；
- 完成表间关联验证；
- 计算核心业务指标；
- 为 Power BI 准备好分析模型。

下一步是在 Power BI 中导入 8 张清洗表，建立模型关系，并制作销售、品类、履约、客户评价和卖家表现仪表盘。
