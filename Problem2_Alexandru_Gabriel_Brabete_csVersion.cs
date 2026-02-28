using System;
using System.Collections.Generic;

namespace SieMarket
{
    // 2.1 CLASS DEFINITIONS

    public class OrderItem
    {
        // We use "private set" to prevent modifying the product name after the object is created.
        // Alternatively, we could use "init".
        public string ProductName { get; private set; }
        public int OrderedQuantity { get; private set; }
        public decimal PricePerUnit { get; private set; }

        public OrderItem(string productName, int orderedQuantity, decimal pricePerUnit)
        {
            ProductName = productName;
            OrderedQuantity = orderedQuantity;
            PricePerUnit = pricePerUnit;
        }

        public decimal CalculateItemTotal()
        {
            return OrderedQuantity * PricePerUnit;
        }
    }

    public class CustomerOrder
    {
        public string CustomerName { get; set; }
        public List<OrderItem> OrderItems { get; set; }

        public CustomerOrder(string customerName)
        {
            CustomerName = customerName;
            OrderItems = new List<OrderItem>();
        }

        // 2.2 FINAL PRICE CALCULATION

        public decimal CalculateFinalPrice()
        {
            decimal TotalPrice = 0;
            foreach (OrderItem item in OrderItems)
            {
                TotalPrice += item.CalculateItemTotal();
            }

            if (TotalPrice > 500)
            {
                decimal discountValue = TotalPrice * 0.10m;
                return TotalPrice - discountValue;
            }

            return TotalPrice;
        }
    }

    // 2.3 and 2.4 ORDER STATISTICS

    public class OrderStatistics
    {
        // 2.3 Identify customer with highest total bought
        public static string GetStarCustomer(List<CustomerOrder> allOrders)
        {
            Dictionary<string, decimal> customerTotals = new Dictionary<string, decimal>();

            foreach (CustomerOrder order in allOrders)
            {
                decimal orderValue = order.CalculateFinalPrice();
                string customerName = order.CustomerName;

                if (customerTotals.ContainsKey(customerName))
                    customerTotals[customerName] += orderValue;
                else
                    customerTotals[customerName] = orderValue;
            }

            string StarCustomer = "";
            decimal MaxBought = 0;

            foreach (var entry in customerTotals)
            {
                if (entry.Value > MaxBought)
                {
                    MaxBought = entry.Value;
                    StarCustomer = entry.Key;
                }
            }

            return StarCustomer;
        }

        // 2.4 Calculate total quantity sold per product (case-insensitive)
        public static Dictionary<string, int> GetProductTotals(List<CustomerOrder> allOrders)
        {
            Dictionary<string, int> productTotals = new Dictionary<string, int>();

            foreach (CustomerOrder order in allOrders)
            {
                foreach (OrderItem item in order.OrderItems)
                {
                    // Normalize product name to lowercase to avoid case-sensitivity
                    string productName = item.ProductName.ToLower();
                    int quantity = item.OrderedQuantity;

                    if (productTotals.ContainsKey(productName))
                        productTotals[productName] += quantity;
                    else
                        productTotals[productName] = quantity;
                }
            }

            return productTotals;
        }
    }

    public class App
    {
        public static void Main(string[] args)
        {
            List<CustomerOrder> allOrders = new List<CustomerOrder>();

            // First order
            CustomerOrder firstOrder = new CustomerOrder("Jhon Popescu");
            firstOrder.OrderItems.Add(new OrderItem("Laptop", 1, 800));
            firstOrder.OrderItems.Add(new OrderItem("Mouse", 2, 20));
            allOrders.Add(firstOrder);

            // Second order
            CustomerOrder secondOrder = new CustomerOrder("Ion Ionescu");
            secondOrder.OrderItems.Add(new OrderItem("Phone", 1, 400));
            secondOrder.OrderItems.Add(new OrderItem("Headphones", 1, 150));
            allOrders.Add(secondOrder);

            // Third order
            CustomerOrder thirdOrder = new CustomerOrder("Alex Alexander");
            thirdOrder.OrderItems.Add(new OrderItem("mouse", 1, 200));       // lowercase to test case-insensitivity
            thirdOrder.OrderItems.Add(new OrderItem("Headphones", 1, 250));
            allOrders.Add(thirdOrder);

            // 2.1 DISPLAY ORDER ITEMS DETAILS

            Console.WriteLine("2.1 ORDER ITEMS DETAILS: ");
            foreach (CustomerOrder order in allOrders)
            {
                Console.WriteLine("Customer: " + order.CustomerName);
                foreach (OrderItem item in order.OrderItems)
                {
                    decimal itemTotal = item.CalculateItemTotal();
                    Console.WriteLine("Product: " + item.ProductName + " Quantity: " + item.OrderedQuantity + " Price per Unit: " + item.PricePerUnit + " Item Total: " + itemTotal + " EUR");
                }
            }

            // 2.2 DISPLAY FINAL ORDER TOTALS

            Console.WriteLine("\n2.2 ORDER TOTALS: ");
            foreach (CustomerOrder order in allOrders)
            {
                decimal finalPrice = order.CalculateFinalPrice();
                Console.WriteLine("Customer: " + order.CustomerName + " Final Price: " + finalPrice + " EUR");
            }

            // 2.3 STAR CUSTOMER

            Console.WriteLine("\n2.3 TOP CUSTOMER: ");
            string StarCustomer = OrderStatistics.GetStarCustomer(allOrders);
            Console.WriteLine("Customer with highest total bought: " + StarCustomer);

            // 2.4 PRODUCT TOTALS (CASE-INSENSITIVE)

            Console.WriteLine("\n2.4 PRODUCT TOTALS: ");
            var productTotals = OrderStatistics.GetProductTotals(allOrders);
            foreach (var entry in productTotals)
            {
                Console.WriteLine(entry.Key + " - Total Quantity Sold: " + entry.Value);
            }
        }
    }
}