@isTest
public class InventoryManagerTest {

    // ============================================================
    // TEST DATA
    // ============================================================

    @testSetup
    static void setupTestData() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            new Re_Plastic_Innovations_Recycled_Product__c(
                Stock_Level__c = 50,
                Threshold__c = 100
            );

        insert product;
    }


    // ============================================================
    // TEST 1
    // PROCESS ORDER - ENOUGH STOCK
    // ============================================================

    @isTest
    static void testProcessOrderStock() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Quantity__c = 20
            );

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>{
                order
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            30,
            updatedProduct.Stock_Level__c,
            'Stock should reduce from 50 to 30'
        );
    }


    // ============================================================
    // TEST 2
    // INSUFFICIENT STOCK - CREATE RESTOCK REQUEST
    // ============================================================

    @isTest
    static void testInsufficientStockCreatesRestock() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Quantity__c = 80
            );

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>{
                order
            }
        );

        Test.stopTest();

        List<Re_Plastic_Innovations_Restock_Request__c> requests =
            [
                SELECT
                    Id,
                    Re_Plastic_Innovations_Recycled_Product__c,
                    Requested_Quantity__c,
                    Status__c
                FROM Re_Plastic_Innovations_Restock_Request__c
            ];

        System.assertEquals(
            1,
            requests.size(),
            'One restock request should be created'
        );

        System.assertEquals(
            product.Id,
            requests[0].Re_Plastic_Innovations_Recycled_Product__c,
            'Restock request should be linked to the correct product'
        );

        System.assertEquals(
            30,
            requests[0].Requested_Quantity__c,
            'Required restock quantity should be 30'
        );

        System.assertEquals(
            'Pending',
            requests[0].Status__c,
            'New restock request should be Pending'
        );
    }


    // ============================================================
    // TEST 3
    // PROCESS RESTOCK APPROVAL
    // ============================================================

    @isTest
    static void testProcessRestockApproval() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c restock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Requested_Quantity__c = 20,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                restock
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            70,
            updatedProduct.Stock_Level__c,
            'Stock should increase from 50 to 70'
        );
    }


    // ============================================================
    // TEST 4
    // ORDER TRIGGER
    // ============================================================

    @isTest
    static void testOrderTrigger() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Quantity__c = 10
            );

        Test.startTest();

        insert order;

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            40,
            updatedProduct.Stock_Level__c,
            'Order trigger should reduce stock from 50 to 40'
        );
    }


    // ============================================================
    // TEST 5
    // RESTOCK APPROVAL TRIGGER
    // ============================================================

    @isTest
    static void testRestockApprovalTrigger() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c restock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Requested_Quantity__c = 25,
                Status__c = 'Pending'
            );

        insert restock;

        Test.startTest();

        restock.Status__c = 'Approved';
        update restock;

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            75,
            updatedProduct.Stock_Level__c,
            'Approved restock should increase stock from 50 to 75'
        );
    }


    // ============================================================
    // TEST 6
    // EMAIL NOTIFICATION
    // ============================================================

    @isTest
    static void testEmailNotification() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c restock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Test.startTest();

        EmailNotificationHelper.sendRestockNotification(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                restock
            }
        );

        Test.stopTest();

        System.assertEquals(
            'Approved',
            restock.Status__c,
            'Restock request should remain Approved'
        );
    }


    // ============================================================
    // TEST 7
    // EMPTY ORDER LIST
    // ============================================================

    @isTest
    static void testEmptyOrderList() {

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>()
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'No restock request should be created'
        );
    }


    // ============================================================
    // TEST 8
    // EMPTY RESTOCK LIST
    // ============================================================

    @isTest
    static void testEmptyRestockList() {

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>()
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'No restock request should exist'
        );
    }


    // ============================================================
    // TEST 9
    // NULL ORDER VALUES
    // ============================================================

    @isTest
    static void testNullOrderValues() {

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Quantity__c = null,
                Re_Plastic_Innovations_Recycled_Product__c = null
            );

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>{
                order
            }
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'Null order values should be handled safely'
        );
    }


    // ============================================================
    // TEST 10
    // NULL PRODUCT STOCK DURING RESTOCK
    // ============================================================

    @isTest
    static void testNullProductStock() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            new Re_Plastic_Innovations_Recycled_Product__c(
                Stock_Level__c = null,
                Threshold__c = 10
            );

        insert product;

        Re_Plastic_Innovations_Restock_Request__c restock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                restock
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            10,
            updatedProduct.Stock_Level__c,
            'Null stock should be treated as zero'
        );
    }


    // ============================================================
    // TEST 11
    // PENDING + APPROVED RESTOCK
    // Covers second-loop continue
    // ============================================================

    @isTest
    static void testPendingRestockApproval() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c pendingRestock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Requested_Quantity__c = 20,
                Status__c = 'Pending'
            );

        Re_Plastic_Innovations_Restock_Request__c approvedRestock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                pendingRestock,
                approvedRestock
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            60,
            updatedProduct.Stock_Level__c,
            'Only the approved restock should update stock'
        );
    }


    // ============================================================
    // TEST 12
    // EMAIL EMPTY LIST
    // ============================================================

    @isTest
    static void testEmptyEmailList() {

        Test.startTest();

        EmailNotificationHelper.sendRestockNotification(
            new List<Re_Plastic_Innovations_Restock_Request__c>()
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'Empty email list should be handled safely'
        );
    }


    // ============================================================
    // TEST 13
    // NULL ORDER LIST
    // ============================================================

    @isTest
    static void testNullOrderList() {

        Test.startTest();

        InventoryManager.processOrderStock(null);

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'Null order list should be handled safely'
        );
    }


    // ============================================================
    // TEST 14
    // NULL RESTOCK LIST
    // ============================================================

    @isTest
    static void testNullRestockList() {

        Test.startTest();

        InventoryManager.processRestockApproval(null);

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'Null restock list should be handled safely'
        );
    }


    // ============================================================
    // TEST 15
    // NULL QUANTITY WITH VALID PRODUCT
    // ============================================================

    @isTest
    static void testNullQuantityWithValidProduct() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Re_Plastic_Innovations_Recycled_Product__c = product.Id,
                Quantity__c = null
            );

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>{
                order
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            50,
            updatedProduct.Stock_Level__c,
            'Null quantity should not change stock'
        );
    }


    // ============================================================
    // TEST 16
    // PRODUCT DOES NOT EXIST
    // ============================================================

    @isTest
    static void testProductDoesNotExist() {

        Account fakeProduct =
            new Account(
                Name = 'Fake Product'
            );

        insert fakeProduct;

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    fakeProduct.Id,
                Quantity__c = 20
            );

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>{
                order
            }
        );

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Re_Plastic_Innovations_Restock_Request__c
            ],
            'Invalid product should not create a restock request'
        );
    }


    // ============================================================
    // TEST 17
    // NULL STOCK DURING ORDER
    // ============================================================

    @isTest
    static void testNullStockCreatesRestock() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            new Re_Plastic_Innovations_Recycled_Product__c(
                Stock_Level__c = null,
                Threshold__c = 10
            );

        insert product;

        Re_Plastic_Innovations_Order__c order =
            new Re_Plastic_Innovations_Order__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Quantity__c = 20
            );

        Test.startTest();

        InventoryManager.processOrderStock(
            new List<Re_Plastic_Innovations_Order__c>{
                order
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Restock_Request__c request =
            [
                SELECT
                    Requested_Quantity__c,
                    Status__c
                FROM Re_Plastic_Innovations_Restock_Request__c
                WHERE
                    Re_Plastic_Innovations_Recycled_Product__c =
                        :product.Id
                LIMIT 1
            ];

        System.assertEquals(
            20,
            request.Requested_Quantity__c,
            'Restock quantity should be 20'
        );

        System.assertEquals(
            'Pending',
            request.Status__c,
            'Restock should be Pending'
        );
    }


    // ============================================================
    // TEST 18
    // MULTIPLE APPROVED RESTOCKS FOR SAME PRODUCT
    // ============================================================

    @isTest
    static void testMultipleApprovedRestocksSameProduct() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c restock1 =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Re_Plastic_Innovations_Restock_Request__c restock2 =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Requested_Quantity__c = 15,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                restock1,
                restock2
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            75,
            updatedProduct.Stock_Level__c,
            'Stock should increase by 25'
        );
    }


    // ============================================================
    // TEST 19
    // INVALID RESTOCK PRODUCT
    // ============================================================

    @isTest
    static void testInvalidRestockProduct() {

        Account fakeProduct =
            new Account(
                Name = 'Invalid Restock Product'
            );

        insert fakeProduct;

        Re_Plastic_Innovations_Restock_Request__c restock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    fakeProduct.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                restock
            }
        );

        Test.stopTest();

        System.assertEquals(
            50,
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :[
                    SELECT Id
                    FROM Re_Plastic_Innovations_Recycled_Product__c
                    LIMIT 1
                ].Id
            ].Stock_Level__c,
            'Invalid product should not update the real product'
        );
    }


    // ============================================================
    // TEST 20
    // RESTOCK NULL QUANTITY
    // ============================================================

    @isTest
    static void testRestockNullQuantity() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c nullQuantity =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Requested_Quantity__c = null,
                Status__c = 'Approved'
            );

        Re_Plastic_Innovations_Restock_Request__c validRestock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                nullQuantity,
                validRestock
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            60,
            updatedProduct.Stock_Level__c,
            'Only the valid restock should update stock'
        );
    }


    // ============================================================
    // TEST 21
    // RESTOCK NULL PRODUCT
    // ============================================================

    @isTest
    static void testRestockNullProduct() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c nullProduct =
            new Re_Plastic_Innovations_Restock_Request__c(
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Re_Plastic_Innovations_Restock_Request__c validRestock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Requested_Quantity__c = 10,
                Status__c = 'Approved'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                nullProduct,
                validRestock
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            60,
            updatedProduct.Stock_Level__c,
            'Only the valid restock should update stock'
        );
    }


    // ============================================================
    // TEST 22
    // PENDING RESTOCK ONLY
    // Covers productIds.isEmpty() in processRestockApproval
    // ============================================================

    @isTest
    static void testPendingRestockOnly() {

        Re_Plastic_Innovations_Recycled_Product__c product =
            [
                SELECT Id, Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                LIMIT 1
            ];

        Re_Plastic_Innovations_Restock_Request__c pendingRestock =
            new Re_Plastic_Innovations_Restock_Request__c(
                Re_Plastic_Innovations_Recycled_Product__c =
                    product.Id,
                Requested_Quantity__c = 20,
                Status__c = 'Pending'
            );

        Test.startTest();

        InventoryManager.processRestockApproval(
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                pendingRestock
            }
        );

        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c updatedProduct =
            [
                SELECT Stock_Level__c
                FROM Re_Plastic_Innovations_Recycled_Product__c
                WHERE Id = :product.Id
            ];

        System.assertEquals(
            50,
            updatedProduct.Stock_Level__c,
            'Pending restock should not change stock'
        );
    }
}