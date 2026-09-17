create database CACIITG;
use CACIITG;

-- imported our feature engineered dataset customer_features
-- converted the datatype of imported default double type to float type
ALTER TABLE customer_features MODIFY COLUMN Review_Rating FLOAT;
ALTER TABLE customer_features 
    MODIFY COLUMN Prev_Norm FLOAT, 
    MODIFY COLUMN Freq_Norm FLOAT, 
    MODIFY COLUMN Spend_Norm FLOAT, 
    MODIFY COLUMN Rating_Norm FLOAT, 
    MODIFY COLUMN Loyalty_A FLOAT, 
    MODIFY COLUMN Loyalty_B FLOAT, 
    MODIFY COLUMN Customer_Value_Score FLOAT, 
    MODIFY COLUMN Organic_Demand_Score FLOAT;

-- dataset view
select * from customer_features;

-- #1 Customer Value Pyramid: 
-- What separates high-value customers from low-value customers? how value is distributed across different customers. 
-- findings: As customer value increases, Average purchase amount increases, Purchase history increases, Purchase frequency increases
-- VIP customers require special retention strategies as they buy more and the average order value is high.
SELECT
    Value_Tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(CAST(Purchase_Amount_USD AS FLOAT)),2) AS avg_purchase_usd,
    ROUND(AVG(CAST(Previous_Purchases AS FLOAT)),2) AS avg_previous_purchases,
    ROUND(AVG(CAST(Frequency_Score AS FLOAT)),2) AS avg_frequency

FROM customer_features
GROUP BY Value_Tier
ORDER BY
    CASE
        WHEN Value_Tier = 'Low Value' THEN 1
        WHEN Value_Tier = 'Medium Value' THEN 2
        WHEN Value_Tier = 'High Value' THEN 3
        WHEN Value_Tier = 'VIP' THEN 4
    END;
    
#2A Loyal vs Discount-Driven Customers: Is the discount and promo program building loyalty?
-- findings: Discounts does not have any significant impact on customer behaviour. The differences are very small.
-- Loyalty is not dependent on Discount offered. if the champion customers are buying almost equally even without discount, then the brand may be over-discounting its elite customers.
-- Non discount champion customers are higher than discount champion customers. Champion customers may not require heavy discounts.
SELECT
    Loyalty_A_Tier,
    Discount_Applied,
    COUNT(*) AS customers,
    ROUND(AVG(Purchase_Amount_USD),2) AS avg_purchase_usd,
    ROUND(AVG(Previous_Purchases),2) AS avg_previous_purchases
FROM customer_features
GROUP BY
    Loyalty_A_Tier,
    Discount_Applied
ORDER BY
    CASE
        WHEN Loyalty_A_Tier = 'Low Loyalty' THEN 1
        WHEN Loyalty_A_Tier = 'Medium Loyalty' THEN 2
        WHEN Loyalty_A_Tier = 'High Loyalty' THEN 3
        WHEN Loyalty_A_Tier = 'Champion' THEN 4
    END;
    
#2B Top Customers (Actual High-Value Customers)
-- top customers likely to be buying two years from now
-- findings: High value customers are defined more by sustained engagement, high purchase frequency and high purchase history.
SELECT
    Customer_Id,
    Customer_Value_Score,
    Loyalty_A,
    Value_Tier,
    Loyalty_A_Tier,
    Purchase_Amount_USD,
    Previous_Purchases,
    Frequency_Score,
    Discount_Independence
FROM customer_features
ORDER BY Customer_Value_Score DESC
LIMIT 100;



#3 High-Value Customer Profile (What does the brand’s best customer look like?)
#3A VIP Gender Profile 
-- findings: Roughly 70% of VIP customers are male. Males buy more. The brand can think of a targeted strategy.
SELECT
    gender,
    COUNT(*) AS customers,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_usd,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases
FROM customer_features
WHERE value_tier = 'VIP'
GROUP BY gender
ORDER BY customers DESC;

#3B VIP Category Profile
-- findinds: clothing is most popular amongst vip customers. Clothing should be brand's primary retention category.
SELECT
    category,
    COUNT(*) AS customers,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_usd,
    ROUND(AVG(previous_purchases),2) AS avg_previous_purchases
FROM customer_features
WHERE value_tier = 'VIP'
GROUP BY category
ORDER BY avg_purchase_usd DESC;

#3C VIP Payment Preference
-- findings: payment method is not a significant differentiator of customer quality.
SELECT
    payment_method,
    COUNT(*) AS customers,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_usd
FROM customer_features
WHERE value_tier = 'VIP'
GROUP BY payment_method
ORDER BY avg_purchase_usd DESC;

#3D VIP Shipping Preference
-- findings: Express shipping customers show the highest purchase value. VIP customers give priority to shipping speed. They are not concerned about cost saving through free shipping.
SELECT
    shipping_type,
    COUNT(*) AS customers,
    ROUND(AVG(purchase_amount_usd),2) AS avg_purchase_usd
FROM customer_features
WHERE value_tier = 'VIP'
GROUP BY shipping_type
ORDER BY avg_purchase_usd DESC;



#4 Loyalty Distribution Across Value Tiers (to check whether High Value = High Loyalty)
-- Who are the customers likely to still be buying two years from now?
-- findings: VIP customers are highly loyal customers. Nearly 84% of VIP customers are highly Loyaly. Brand must prioritize these customers above others.
-- similarly low value customers are weak in engagement and have low loyalty. These customers should be given less priority.
-- High value customers are valuable but not highly loyal. The brand should also focus on these customers for retention.
-- which profiles show the strongest repeat purchase behavior? (Answer: Champion, High Loyalty, VIP customers)
SELECT
    Value_Tier,
    Loyalty_A_Tier,
    COUNT(*) AS customers
FROM customer_features
GROUP BY
    Value_Tier,
    Loyalty_A_Tier
ORDER BY
    Value_Tier,
    Loyalty_A_Tier;

#5 Organic vs Discount-Driven Customers
-- findings: Organic Demand increases strongly with customer value and so is average previous purchases. Discount offerings does not strongly separate customers. 
SELECT
    Value_Tier,
    ROUND(AVG(Organic_Demand_Score),2) AS avg_organic_score,
    ROUND(AVG(Discount_Independence),2) AS avg_discount_independence,
    ROUND(AVG(Previous_Purchases),2) AS avg_previous_purchases
FROM customer_features
GROUP BY Value_Tier
ORDER BY
    CASE
        WHEN Value_Tier = 'Low Value' THEN 1
        WHEN Value_Tier = 'Medium Value' THEN 2
        WHEN Value_Tier = 'High Value' THEN 3
        WHEN Value_Tier = 'VIP' THEN 4
    END;
    
#6 Geographic Opportunity Analysis
#6A Geographic Performance Overview (Are there regions with strong traction?)
# Identify states with: high purchase, high loyalty, high organic demand
-- findings: Arizona and Alaska shows highest spend + organic demand + discount independence. 
-- Hawaii shows moderate spend + high loyalty + high organic demand + high discount independence
-- Kansas customers frequently purchase without discounts.
-- Promotional strategies should focus more on regions with strong organic demand, loyalty, previous purchases.
SELECT
    Location,
    COUNT(*) AS customers,
    ROUND(AVG(Purchase_Amount_USD),2) AS avg_purchase_usd,
    ROUND(AVG(Previous_Purchases),2) AS avg_previous_purchases,
    ROUND(AVG(Loyalty_A),2) AS avg_loyalty,
    ROUND(AVG(Organic_Demand_Score),2) AS avg_organic_score,
    ROUND(AVG(Discount_Independence),2) AS avg_discount_independence
FROM customer_features
GROUP BY Location
ORDER BY avg_organic_score DESC;

#6B High-Value Geographic Regions
-- identify regions where the strongest VIP customers are concentrated. Regions with Organic demand.
-- Arizona, Wyoming, Illinois, Alabama, Rhode Island are the strongest VIP target markets.
-- ARIZONA becomes very important in terms of high organic demand and high number of vip customers.
-- ALABAMA vip customers are also good in number with high organic demand, high purchase value.
-- Many smaller geographic regions shows strong high-value and organic customers, suggesting that customer quality varies across regions.
SELECT
    Location,
    COUNT(*) AS vip_customers,
    ROUND(AVG(Customer_Value_Score),2) AS avg_value_score,
    ROUND(AVG(Purchase_Amount_USD),2) AS avg_purchase_usd,
    ROUND(AVG(Organic_Demand_Score),2) AS avg_organic_score
FROM customer_features
WHERE value_tier = 'VIP'
GROUP BY Location
HAVING COUNT(*) >= 10
ORDER BY avg_value_score DESC;

#6C Discount Dependence by Geography
-- Discount-dependent regions vs organic demand regions
-- findings: regions like indiana, Towa, oregon comparatively shows high discount dependence with moderrate organic demand.
-- customers buy products in these top regions mainly because of discounts offered.
-- Arizona, Wyoming and Alabama customers do not rely heavily on discounts for purchase decisions and are highly organic.

SELECT
    Location,
    ROUND(
        AVG(
            CASE
                WHEN Discount_Applied = 'Yes' THEN 1
                ELSE 0
            END
        ),
        2
    ) AS discount_usage_rate,
    ROUND(AVG(Organic_Demand_Score),2) AS avg_organic_score,
    ROUND(AVG(Previous_Purchases),2) AS avg_previous_purchases
FROM customer_features
GROUP BY Location
ORDER BY discount_usage_rate DESC;



#7 Category Retention Analysis
#7A Category Loyalty Analysis
-- Which product categories are associated with lower-tenure customers versus those with high previous purchase counts?
-- findings: Accessories and Footwear had slightly higher repeat-purchase histories. Outerwear customers shows lower engagement relative to other categories.
-- customer value should not be focussed on category as the differences are very minimal. 
SELECT
    Category,
    COUNT(*) AS customers,
    ROUND(AVG(Previous_Purchases),2) AS avg_previous_purchases,
    ROUND(AVG(Loyalty_A),2) AS avg_loyalty,
    ROUND(AVG(Customer_Value_Score),2) AS avg_value_score,
    ROUND(AVG(Organic_Demand_Score),2) AS avg_organic_score
FROM customer_features
GROUP BY Category
ORDER BY avg_previous_purchases DESC;

#7B Category + Discount behaviour
# Determine whether some categories are more promotion-driven.
# very minimal differences observed.
# customer value is driven more by sustained engagement than by discounts offered.
SELECT
    Category,
    Discount_Applied,
    COUNT(*) AS customers,
    ROUND(AVG(Previous_Purchases),2) AS avg_previous_purchases,
    ROUND(AVG(Customer_Value_Score),2) AS avg_value_score
FROM customer_features
GROUP BY
    Category,
    Discount_Applied
ORDER BY
    Category,
    Discount_Applied;
    
 #8 Seasonal Customer Tenure Analysis
 -- Which seasons are associated with lower-tenure customers versus those with high previous purchase counts?
 -- findings: Customer quality, loyalty, and repeat-purchase behavior remain stable across seasons. 
 -- We conclude that customer value is driven more by customer behavior than by seasonality.
 
SELECT
    Season,
    COUNT(*) AS Customers,
    ROUND(AVG(Purchase_Amount_USD),2) AS Avg_Purchase,
    ROUND(AVG(Previous_Purchases),2) AS Avg_Previous_Purchases,
    ROUND(AVG(Frequency_Score),2) AS Avg_Frequency,
    ROUND(AVG(Loyalty_A),2) AS Avg_Loyalty,
    ROUND(AVG(Organic_Demand_Score),2) AS Avg_Organic_Demand
FROM customer_features
GROUP BY Season
ORDER BY Avg_Previous_Purchases DESC;
 
    # Summary Findings   
-- This analysis identified little evidence that discounts influence quality of customers across loyalty tiers, geographies, or product categories. 
-- In contrast, customer value seems to be more related to high purchase frequency, stronger purchase history and not only to discount participation.
-- Many regions including Arizona, Alabama, Alaska, Illinois, Pennsylvania and Hawaii showed comparatively strong combinations of customer value, loyalty, organic demand, and repeat purchases, although each region showed strength in specific dimensions.

