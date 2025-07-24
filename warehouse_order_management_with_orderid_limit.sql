-- ===========================
-- Warehouse Order Management Setup and Process (ORDER_ID capped at 999999)
-- ===========================
SET SERVEROUTPUT ON;
/

DECLARE
    v_order_id        NUMBER;
    v_customer_id     NUMBER := 201; -- Example customer
    v_order_date      DATE := SYSDATE;
    v_status          VARCHAR2(20) := 'NEW';
    -- Example data: list of items and quantities to order
    TYPE item_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    TYPE qty_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    items   item_table;
    qtys    qty_table;
    v_item_id         NUMBER;
    v_quantity        NUMBER;
    v_stock_on_hand   NUMBER;
BEGIN
    -- Example: Ordering 2 items
    items(1) := 1001; qtys(1) := 10;  -- Item 1001, 10 units
    items(2) := 1002; qtys(2) := 5;   -- Item 1002, 5 units

    -- Get the next order id
    SELECT ORDERS_SEQ.NEXTVAL INTO v_order_id FROM dual;

    -- Check if order id exceeds 999999
    IF v_order_id > 999999 THEN
        -- Reset the sequence to 1
        EXECUTE IMMEDIATE 'DROP SEQUENCE ORDERS_SEQ';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ORDERS_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
        SELECT ORDERS_SEQ.NEXTVAL INTO v_order_id FROM dual;
    END IF;

    -- Insert into ORDERS table
    INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, STATUS)
    VALUES (v_order_id, v_customer_id, v_order_date, v_status);

    -- Loop through each item and process order lines
    FOR i IN 1 .. items.COUNT LOOP
        v_item_id := items(i);
        v_quantity := qtys(i);

        -- Check inventory
        SELECT NVL(QUANTITY_ON_HAND, 0)
        INTO v_stock_on_hand
        FROM INVENTORY
        WHERE ITEM_ID = v_item_id
        FOR UPDATE;

        IF v_stock_on_hand >= v_quantity THEN
            -- Insert into ORDER_LINES table
            INSERT INTO ORDER_LINES (ORDER_LINE_ID, ORDER_ID, ITEM_ID, QUANTITY)
            VALUES (ORDER_LINES_SEQ.NEXTVAL, v_order_id, v_item_id, v_quantity);

            -- Reserve stock (deduct from inventory)
            UPDATE INVENTORY
            SET QUANTITY_ON_HAND = QUANTITY_ON_HAND - v_quantity
            WHERE ITEM_ID = v_item_id;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Insufficient stock for item: ' || v_item_id);
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order process completed for order: ' || v_order_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in order process: ' || SQLERRM);
END;
/ 