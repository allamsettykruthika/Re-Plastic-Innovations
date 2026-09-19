public class InventoryManager {

    // ============================================================
    // PROCESS ORDER STOCK
    // ============================================================

    public static void processOrderStock(
        List<Re_Plastic_Innovations_Order__c> orderList
    ) {

        if (orderList == null || orderList.isEmpty()) {
            return;
        }

        Set<Id> productIds = new Set<Id>();

        // Collect product IDs
        for (Re_Plastic_Innovations_Order__c order : orderList) {

            if (order.Re_Plastic_Innovations_Recycled_Product__c != null) {
                productIds.add(
                    order.Re_Plastic_Innovations_Recycled_Product__c
                );
            }
        }

        if (productIds.isEmpty()) {
            return;
        }

        // Get products
        Map<Id, Re_Plastic_Innovations_Recycled_Product__c> productMap =
            new Map<Id, Re_Plastic_Innovations_Recycled_Product__c>(
                [
                    SELECT Id, Stock_Level__c, Threshold__c
                    FROM Re_Plastic_Innovations_Recycled_Product__c
                    WHERE Id IN :productIds
                ]
            );

        // Keep stock changes by Product Id
        Map<Id, Re_Plastic_Innovations_Recycled_Product__c> productsToUpdate =
            new Map<Id, Re_Plastic_Innovations_Recycled_Product__c>();

        List<Re_Plastic_Innovations_Restock_Request__c> restockRequests =
            new List<Re_Plastic_Innovations_Restock_Request__c>();

        // Process orders
        for (Re_Plastic_Innovations_Order__c order : orderList) {

            if (order.Re_Plastic_Innovations_Recycled_Product__c == null ||
                order.Quantity__c == null) {
                continue;
            }

            Re_Plastic_Innovations_Recycled_Product__c product =
                productMap.get(
                    order.Re_Plastic_Innovations_Recycled_Product__c
                );

            // Product does not exist
            if (product == null) {
                continue;
            }

            Decimal currentStock =
                product.Stock_Level__c == null
                ? 0
                : product.Stock_Level__c;

            // Enough stock
            if (currentStock >= order.Quantity__c) {

                product.Stock_Level__c =
                    currentStock - order.Quantity__c;

                productsToUpdate.put(product.Id, product);
            }

            // Not enough stock
            else {

                Decimal requiredQuantity =
                    order.Quantity__c - currentStock;

                restockRequests.add(
                    new Re_Plastic_Innovations_Restock_Request__c(
                        Re_Plastic_Innovations_Recycled_Product__c =
                            product.Id,

                        Requested_Quantity__c =
                            requiredQuantity,

                        Status__c = 'Pending'
                    )
                );
            }
        }

        // Update stock
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate.values();
        }

        // Create restock requests
        if (!restockRequests.isEmpty()) {
            insert restockRequests;
        }
    }


    // ============================================================
    // PROCESS RESTOCK APPROVAL
    // ============================================================

    public static void processRestockApproval(
        List<Re_Plastic_Innovations_Restock_Request__c> restockList
    ) {

        if (restockList == null || restockList.isEmpty()) {
            return;
        }

        Set<Id> productIds = new Set<Id>();

        // Collect approved product IDs
        for (
            Re_Plastic_Innovations_Restock_Request__c restock
            : restockList
        ) {

            if (
                restock.Status__c == 'Approved' &&
                restock.Re_Plastic_Innovations_Recycled_Product__c != null
            ) {

                productIds.add(
                    restock.Re_Plastic_Innovations_Recycled_Product__c
                );
            }
        }

        if (productIds.isEmpty()) {
            return;
        }

        // Query products
        Map<Id, Re_Plastic_Innovations_Recycled_Product__c> productMap =
            new Map<Id, Re_Plastic_Innovations_Recycled_Product__c>(
                [
                    SELECT Id, Stock_Level__c
                    FROM Re_Plastic_Innovations_Recycled_Product__c
                    WHERE Id IN :productIds
                ]
            );

        // Store updated products by Id
        Map<Id, Re_Plastic_Innovations_Recycled_Product__c> productsToUpdate =
            new Map<Id, Re_Plastic_Innovations_Recycled_Product__c>();

        // Process approved restocks
        for (
            Re_Plastic_Innovations_Restock_Request__c restock
            : restockList
        ) {

            if (
                restock.Status__c != 'Approved' ||
                restock.Requested_Quantity__c == null ||
                restock.Re_Plastic_Innovations_Recycled_Product__c == null
            ) {
                continue;
            }

            if (
                !productMap.containsKey(
                    restock.Re_Plastic_Innovations_Recycled_Product__c
                )
            ) {
                continue;
            }

            Re_Plastic_Innovations_Recycled_Product__c product =
                productMap.get(
                    restock.Re_Plastic_Innovations_Recycled_Product__c
                );

            Decimal currentStock =
                productsToUpdate.containsKey(product.Id)
                ? productsToUpdate.get(product.Id).Stock_Level__c
                : product.Stock_Level__c;

            if (currentStock == null) {
                currentStock = 0;
            }

            product.Stock_Level__c =
                currentStock + restock.Requested_Quantity__c;

            productsToUpdate.put(product.Id, product);
        }

        // Update products
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate.values();
        }
    }
}