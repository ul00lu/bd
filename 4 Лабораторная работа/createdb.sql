CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- E1 Магазин
CREATE TABLE shop (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address       VARCHAR(255) NOT NULL,
    open_time     TIME         NOT NULL,
    close_time    TIME         NOT NULL,
    rent_cost     DECIMAL(12,2) NOT NULL CHECK (rent_cost >= 0),
    hall_size     DECIMAL(10,2) NOT NULL CHECK (hall_size > 0),
    storage_size  DECIMAL(10,2) NOT NULL CHECK (storage_size > 0),
    cash_count    INT          NOT NULL CHECK (cash_count > 0),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- E3 Должность
CREATE TABLE position (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(50) NOT NULL UNIQUE,
    description TEXT        NOT NULL,
    duties      TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_position_name CHECK (name IN ('курьер', 'продавец-консультант', 'администратор'))
);


-- E2 Физлицо (Сотрудник)
CREATE TABLE employee (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id       UUID        NOT NULL,
    position_id   UUID        NOT NULL,
    passport_data VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL UNIQUE,
    last_name     VARCHAR(100) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    middle_name   VARCHAR(100) NOT NULL,
    birth_date    DATE         NOT NULL,
    registration  VARCHAR(255) NOT NULL,
    education     VARCHAR(255) NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_employee_shop     FOREIGN KEY (shop_id)     REFERENCES shop(id),
    CONSTRAINT fk_employee_position FOREIGN KEY (position_id) REFERENCES position(id)
);


-- E4 Трудовой договор
CREATE TABLE employment_contract (
    id              UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id         UUID          NOT NULL,
    employee_id     UUID          NOT NULL,
    position_id     UUID          NOT NULL,
    start_date      DATE          NOT NULL,
    end_date        DATE          NOT NULL,
    salary          DECIMAL(12,2) NOT NULL CHECK (salary >= 0),
    notes           TEXT          NOT NULL,
    admin_signature VARCHAR(255)  NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_contract_shop     FOREIGN KEY (shop_id)     REFERENCES shop(id),
    CONSTRAINT fk_contract_employee FOREIGN KEY (employee_id) REFERENCES employee(id),
    CONSTRAINT fk_contract_position FOREIGN KEY (position_id) REFERENCES position(id),
    CONSTRAINT chk_contract_dates   CHECK (end_date > start_date)
);


-- E5 Платёжное поручение
CREATE TABLE payment_order (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id  UUID NOT NULL,
    contract_id  UUID NOT NULL,
    amount       DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    payment_date DATE NOT NULL,
    reason       VARCHAR(255) NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_payment_employee FOREIGN KEY (employee_id) REFERENCES employee(id),
    CONSTRAINT fk_payment_contract FOREIGN KEY (contract_id) REFERENCES employment_contract(id),
    CONSTRAINT chk_payment_reason  CHECK (reason IN ('зп', 'плата за доставку', 'бонус за продажу'))
);


-- E6 График работы
CREATE TABLE work_schedule (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id   UUID        NOT NULL,
    contract_id   UUID        NOT NULL,
    schedule_date DATE        NOT NULL,
    is_work_day   BOOLEAN     NOT NULL DEFAULT TRUE,
    work_start    TIME        NOT NULL,
    work_end      TIME        NOT NULL,
    break_start   TIME        NOT NULL,
    break_end     TIME        NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_schedule_employee FOREIGN KEY (employee_id) REFERENCES employee(id),
    CONSTRAINT fk_schedule_contract FOREIGN KEY (contract_id) REFERENCES employment_contract(id)
);


-- E7 Поставщик
CREATE TABLE supplier (
    id          UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255) NOT NULL UNIQUE,
    inn         VARCHAR(20)  NOT NULL UNIQUE,
    contact     VARCHAR(255) NOT NULL,
    address     VARCHAR(255) NOT NULL,
    description TEXT         NOT NULL,
    type        VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_supplier_type CHECK (type IN ('юр. лицо', 'ИП', 'физ. лицо'))
);

-- E8 Документ поставки
CREATE TABLE delivery_document (
    id            UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id       UUID          NOT NULL,
    supplier_id   UUID          NOT NULL,
    delivery_cost DECIMAL(12,2) NOT NULL CHECK (delivery_cost >= 0),
    quantity      INT           NOT NULL CHECK (quantity > 0),
    order_time    TIMESTAMP     NOT NULL,
    delivery_time TIMESTAMP     NOT NULL,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_delivery_doc_shop     FOREIGN KEY (shop_id)     REFERENCES shop(id),
    CONSTRAINT fk_delivery_doc_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(id)
);


-- E9 Одежда
CREATE TABLE clothing (
    id             UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    article        VARCHAR(50)   NOT NULL UNIQUE,
    type           VARCHAR(100)  NOT NULL,
    color          VARCHAR(50)   NOT NULL,
    size           VARCHAR(20)   NOT NULL,
    kind           VARCHAR(50)   NOT NULL,
    purchase_price DECIMAL(12,2) NOT NULL CHECK (purchase_price >= 0),
    sale_price     DECIMAL(12,2) NOT NULL CHECK (sale_price >= 0),
    stock_quantity INT           NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    brand          VARCHAR(100)  NOT NULL,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_clothing_type  CHECK (type  IN ('футболка','брюки','платье','куртка','пальто','свитер','юбка','шорты','рубашка','костюм')),
    CONSTRAINT chk_clothing_color CHECK (color IN ('красный','синий','белый','чёрный','зелёный','жёлтый','серый','бежевый','розовый','фиолетовый')),
    CONSTRAINT chk_clothing_size  CHECK (size  IN ('XS','S','M','L','XL','XXL')),
    CONSTRAINT chk_clothing_kind  CHECK (kind  IN ('мужская','женская','детская')),
    CONSTRAINT chk_clothing_brand CHECK (brand IN ('Zara','H&M','Adidas','Nike','Boss','Gucci','Armani','Prada','Mango','Uniqlo'))
);


-- E10 Комплект
CREATE TABLE outfit (
    id          UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(255)  NOT NULL UNIQUE,
    total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- E14 Дисконтная карта
CREATE TABLE discount_card (
    id            UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone         VARCHAR(20)  NOT NULL UNIQUE,
    email         VARCHAR(255) NOT NULL UNIQUE,
    full_name     VARCHAR(255) NOT NULL,
    discount_pct  DECIMAL(5,2) NOT NULL CHECK (discount_pct >= 0 AND discount_pct <= 100),
    registered_at DATE         NOT NULL DEFAULT CURRENT_DATE,
    birth_date    DATE         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- E11 Чек
CREATE TABLE receipt (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id          UUID NOT NULL,
    employee_id      UUID NOT NULL,
    discount_card_id   UUID,
    receipt_date       TIMESTAMP NOT NULL,
    customer_full_name VARCHAR(255),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_receipt_shop     FOREIGN KEY (shop_id)          REFERENCES shop(id),
    CONSTRAINT fk_receipt_employee FOREIGN KEY (employee_id)      REFERENCES employee(id),
    CONSTRAINT fk_receipt_discount FOREIGN KEY (discount_card_id) REFERENCES discount_card(id)
);


-- E12 Заказ
CREATE TABLE customer_order (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id          UUID NOT NULL,
    employee_id      UUID NOT NULL,
    discount_card_id UUID,
    order_date       TIMESTAMP NOT NULL DEFAULT NOW(),
    comment          TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_order_shop     FOREIGN KEY (shop_id)          REFERENCES shop(id),
    CONSTRAINT fk_order_employee FOREIGN KEY (employee_id)      REFERENCES employee(id),
    CONSTRAINT fk_order_discount FOREIGN KEY (discount_card_id) REFERENCES discount_card(id)
);


-- E13 Накладная доставки
CREATE TABLE delivery_note (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    courier_id          UUID NOT NULL,
    order_id            UUID NOT NULL,
    order_date          TIMESTAMP NOT NULL,
    planned_delivery_at TIMESTAMP,
    actual_delivery_at  TIMESTAMP,
    delivery_address    VARCHAR(255) NOT NULL,
    customer_phone      VARCHAR(20),
    customer_full_name  VARCHAR(255),
    customer_signed     BOOLEAN NOT NULL DEFAULT FALSE,
    review              TEXT,
    shop_mark           VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_delivery_note_courier FOREIGN KEY (courier_id) REFERENCES employee(id),
    CONSTRAINT fk_delivery_note_order   FOREIGN KEY (order_id)   REFERENCES customer_order(id)
);


-- Магазин <-> Одежда
CREATE TABLE shop_clothing (
    shop_id     UUID NOT NULL,
    clothing_id UUID NOT NULL,
    quantity    INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (shop_id, clothing_id),
    CONSTRAINT fk_sc_shop     FOREIGN KEY (shop_id)     REFERENCES shop(id),
    CONSTRAINT fk_sc_clothing FOREIGN KEY (clothing_id) REFERENCES clothing(id)
);


-- Документ поставки <-> Одежда
CREATE TABLE delivery_document_clothing (
    delivery_document_id UUID NOT NULL,
    clothing_id          UUID NOT NULL,
    quantity             INT NOT NULL CHECK (quantity > 0),
    price                DECIMAL(12,2) CHECK (price >= 0),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (delivery_document_id, clothing_id),
    CONSTRAINT fk_ddc_doc     FOREIGN KEY (delivery_document_id) REFERENCES delivery_document(id),
    CONSTRAINT fk_ddc_clothing FOREIGN KEY (clothing_id)         REFERENCES clothing(id)
);


-- Одежда <-> Комплект
CREATE TABLE clothing_outfit (
    clothing_id UUID NOT NULL,
    outfit_id   UUID NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (clothing_id, outfit_id),
    CONSTRAINT fk_co_clothing FOREIGN KEY (clothing_id) REFERENCES clothing(id),
    CONSTRAINT fk_co_outfit   FOREIGN KEY (outfit_id)   REFERENCES outfit(id)
);


-- Одежда <-> Чек
CREATE TABLE receipt_clothing (
    receipt_id  UUID NOT NULL,
    clothing_id UUID NOT NULL,
    quantity    INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price       DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (receipt_id, clothing_id),
    CONSTRAINT fk_rc_receipt  FOREIGN KEY (receipt_id)  REFERENCES receipt(id),
    CONSTRAINT fk_rc_clothing FOREIGN KEY (clothing_id) REFERENCES clothing(id)
);


-- Одежда <-> Заказ
CREATE TABLE order_clothing (
    order_id    UUID NOT NULL,
    clothing_id UUID NOT NULL,
    quantity    INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price       DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (order_id, clothing_id),
    CONSTRAINT fk_oc_order    FOREIGN KEY (order_id)    REFERENCES customer_order(id),
    CONSTRAINT fk_oc_clothing FOREIGN KEY (clothing_id) REFERENCES clothing(id)
);


-- Одежда <-> Накладная
CREATE TABLE delivery_note_clothing (
    delivery_note_id UUID NOT NULL,
    clothing_id      UUID NOT NULL,
    quantity         INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price            DECIMAL(12,2) NOT NULL CHECK (price >= 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (delivery_note_id, clothing_id),
    CONSTRAINT fk_dnc_note    FOREIGN KEY (delivery_note_id) REFERENCES delivery_note(id),
    CONSTRAINT fk_dnc_clothing FOREIGN KEY (clothing_id)     REFERENCES clothing(id)
);