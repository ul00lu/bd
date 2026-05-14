const { faker } = require('@faker-js/faker/locale/ru');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');

faker.seed(42);



function uid() {
    return uuidv4();
}

function sq(val) {
    if (val === null || val === undefined) return 'NULL';
    return `'${String(val).replace(/'/g, "''")}'`;
}

function bool(val) {
    return val ? 'TRUE' : 'FALSE';
}

function randInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randFloat(min, max) {
    return parseFloat((Math.random() * (max - min) + min).toFixed(2));
}

function randItem(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

function randSample(arr, n) {
    return [...arr].sort(() => Math.random() - 0.5).slice(0, Math.min(n, arr.length));
}

function randDate(start, end) {
    const d = new Date(new Date(start).getTime() + Math.random() * (new Date(end) - new Date(start)));
    return d.toISOString().split('T')[0];
}

function randDatetime(start, end) {
    const d = new Date(new Date(start).getTime() + Math.random() * (new Date(end) - new Date(start)));
    return d.toISOString().replace('T', ' ').substring(0, 19);
}



const COUNT = {
    shops:         5,
    employees:     40,
    suppliers:     10,
    clothes:       80,
    outfits:       15,
    discountCards: 60,
    deliveries:    30,
    receipts:      100,
    orders:        50,
    scheduleDays:  90,
};

const POSITION_IDS = {
    'курьер':               '11111111-0000-0000-0000-000000000001',
    'продавец-консультант': '11111111-0000-0000-0000-000000000002',
    'администратор':        '11111111-0000-0000-0000-000000000003',
};

const POSITIONS   = Object.keys(POSITION_IDS);
const CLOTH_TYPES = ['футболка', 'брюки', 'платье', 'куртка', 'пальто', 'свитер', 'юбка', 'шорты', 'рубашка', 'костюм'];
const COLORS      = ['красный', 'синий', 'белый', 'чёрный', 'зелёный', 'жёлтый', 'серый', 'бежевый', 'розовый', 'фиолетовый'];
const SIZES       = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
const KINDS       = ['мужская', 'женская', 'детская'];
const BRANDS      = ['Zara', 'H&M', 'Adidas', 'Nike', 'Boss', 'Gucci', 'Armani', 'Prada', 'Mango', 'Uniqlo'];
const SUP_TYPES   = ['юр. лицо', 'ИП', 'физ. лицо'];
const PAY_REASONS = ['зп', 'плата за доставку', 'бонус за продажу'];
const EDUCATIONS  = ['среднее', 'среднее специальное', 'высшее', 'неполное высшее'];
const NOTES       = ['стандартный', 'ненормированный день', 'частичная занятость', null];
const SHOP_MARKS  = ['доставлено', 'из магазина в магазин', null];

const sql = [];

function insert(table, cols, vals) {
    sql.push(`INSERT INTO ${table} (${cols}) VALUES (${vals}) ON CONFLICT DO NOTHING;`);
}

// Магазин
const shopIds = [];
for (let i = 0; i < COUNT.shops; i++) {
    const id = uid();
    shopIds.push(id);
    insert('shop',
        'id, address, working_hours, rent_cost, hall_size, storage_size, cash_count',
        [
            sq(id),
            sq(faker.location.streetAddress()),
            sq(`${randInt(8, 10)}:00 - ${randInt(19, 22)}:00`),
            randFloat(50000, 300000),
            randFloat(100, 500),
            randFloat(50, 300),
            randInt(2, 8),
        ].join(', ')
    );
}

// Физлицо 
const employeeIds      = [];
const employeePosition = {};
const usedPassports    = new Set();
const usedEmpPhones    = new Set();

for (let i = 0; i < COUNT.employees; i++) {
    const id      = uid();
    const posName = randItem(POSITIONS);
    employeeIds.push(id);
    employeePosition[id] = posName;

    let passport;
    do { passport = faker.string.alphanumeric(9).toUpperCase(); } while (usedPassports.has(passport));
    usedPassports.add(passport);

    let phone;
    do { phone = faker.phone.number().substring(0, 20); } while (usedEmpPhones.has(phone));
    usedEmpPhones.add(phone);

    insert('employee',
        'id, shop_id, position_id, passport_data, phone, last_name, first_name, middle_name, birth_date, registration, education',
        [
            sq(id),
            sq(randItem(shopIds)),
            sq(POSITION_IDS[posName]),
            sq(passport),
            sq(phone),
            sq(faker.person.lastName()),
            sq(faker.person.firstName()),
            sq(faker.person.middleName()),
            sq(randDate('1970-01-01', '2000-12-31')),
            sq(faker.location.streetAddress()),
            sq(randItem(EDUCATIONS)),
        ].join(', ')
    );
}

// Трудовой договор
const contractByEmp = {};
for (const empId of employeeIds) {
    const id = uid();
    contractByEmp[empId] = id;
    insert('employment_contract',
        'id, shop_id, employee_id, position_id, start_date, end_date, salary, notes, admin_signature',
        [
            sq(id),
            sq(randItem(shopIds)),
            sq(empId),
            sq(POSITION_IDS[employeePosition[empId]]),
            sq(randDate('2020-01-01', '2023-06-01')),
            sq(randDate('2024-01-01', '2027-12-31')),
            randFloat(30000, 150000),
            sq(randItem(NOTES)),
            sq(faker.person.lastName()),
        ].join(', ')
    );
}

// Платёжное поручение
for (const empId of employeeIds) {
    const n = randInt(1, 4);
    for (let j = 0; j < n; j++) {
        insert('payment_order',
            'id, employee_id, contract_id, amount, payment_date, reason',
            [
                sq(uid()),
                sq(empId),
                sq(contractByEmp[empId]),
                randFloat(10000, 200000),
                sq(randDate('2023-01-01', '2026-04-01')),
                sq(randItem(PAY_REASONS)),
            ].join(', ')
        );
    }
}

// График работы
const today         = new Date();
const scheduleStart = new Date(today);
scheduleStart.setDate(today.getDate() - COUNT.scheduleDays);

for (const empId of employeeIds) {
    const cur = new Date(scheduleStart);
    while (cur <= today) {
        const isWorkDay  = Math.random() > 0.25;
        const workStart  = isWorkDay ? `${String(randInt(8, 10)).padStart(2, '0')}:00:00` : null;
        const workEnd    = isWorkDay ? `${String(randInt(17, 20)).padStart(2, '0')}:00:00` : null;
        const breakStart = isWorkDay ? '13:00:00' : null;
        const breakEnd   = isWorkDay ? '14:00:00' : null;
        insert('work_schedule',
            'id, employee_id, contract_id, schedule_date, is_work_day, work_start, work_end, break_start, break_end',
            [
                sq(uid()),
                sq(empId),
                sq(contractByEmp[empId]),
                sq(cur.toISOString().split('T')[0]),
                bool(isWorkDay),
                sq(workStart),
                sq(workEnd),
                sq(breakStart),
                sq(breakEnd),
            ].join(', ')
        );
        cur.setDate(cur.getDate() + 1);
    }
}

// Поставщик
const supplierIds  = [];
const usedInns     = new Set();
const usedSupNames = new Set();

for (let i = 0; i < COUNT.suppliers; i++) {
    const id = uid();
    supplierIds.push(id);

    let inn;
    do { inn = String(randInt(1000000000, 9999999999)); } while (usedInns.has(inn));
    usedInns.add(inn);

    let name;
    do { name = faker.company.name(); } while (usedSupNames.has(name));
    usedSupNames.add(name);

    insert('supplier',
        'id, inn, name, contact, address, description, type',
        [
            sq(id),
            sq(inn),
            sq(name),
            sq(faker.person.lastName()),
            sq(faker.location.streetAddress()),
            sq(faker.lorem.sentence()),
            sq(randItem(SUP_TYPES)),
        ].join(', ')
    );
}

// Одежда
const clothingIds  = [];
const usedArticles = new Set();

for (let i = 0; i < COUNT.clothes; i++) {
    const id = uid();
    clothingIds.push(id);

    let article;
    do { article = faker.string.alphanumeric(2).toUpperCase() + '-' + randInt(1000, 9999); } while (usedArticles.has(article));
    usedArticles.add(article);

    const purchasePrice = randFloat(500, 10000);
    const salePrice     = parseFloat((purchasePrice * randFloat(1.3, 3.0)).toFixed(2));

    insert('clothing',
        'id, article, type, color, size, kind, purchase_price, sale_price, stock_quantity, brand',
        [
            sq(id),
            sq(article),
            sq(randItem(CLOTH_TYPES)),
            sq(randItem(COLORS)),
            sq(randItem(SIZES)),
            sq(randItem(KINDS)),
            purchasePrice,
            salePrice,
            randInt(0, 50),
            sq(randItem(BRANDS)),
        ].join(', ')
    );
}

// Комплект
const outfitIds       = [];
const usedOutfitNames = new Set();

for (let i = 0; i < COUNT.outfits; i++) {
    const id = uid();
    outfitIds.push(id);

    let name;
    do { name = `Комплект ${faker.word.adjective()} ${i + 1}`; } while (usedOutfitNames.has(name));
    usedOutfitNames.add(name);

    insert('outfit',
        'id, name, total_price',
        [sq(id), sq(name), randFloat(3000, 30000)].join(', ')
    );
}

// Дисконтная карта
const discountCardIds = [];
const usedEmails      = new Set();
const usedDiscPhones  = new Set();

for (let i = 0; i < COUNT.discountCards; i++) {
    const id = uid();
    discountCardIds.push(id);

    let email;
    do { email = faker.internet.email(); } while (usedEmails.has(email));
    usedEmails.add(email);

    let phone;
    do { phone = faker.phone.number().substring(0, 20); } while (usedDiscPhones.has(phone));
    usedDiscPhones.add(phone);

    insert('discount_card',
        'id, email, phone, full_name, discount_pct, registered_at, birth_date',
        [
            sq(id),
            sq(email),
            sq(phone),
            sq(`${faker.person.lastName()} ${faker.person.firstName()}`),
            randFloat(1, 30),
            sq(randDate('2018-01-01', '2025-12-31')),
            sq(randDate('1960-01-01', '2005-12-31')),
        ].join(', ')
    );
}

// Документ поставки
const deliveryDocIds = [];
for (let i = 0; i < COUNT.deliveries; i++) {
    const id = uid();
    deliveryDocIds.push(id);
    insert('delivery_document',
        'id, shop_id, supplier_id, delivery_cost, quantity, order_time, delivery_time',
        [
            sq(id),
            sq(randItem(shopIds)),
            sq(randItem(supplierIds)),
            randFloat(10000, 500000),
            randInt(10, 200),
            sq(randDatetime('2023-01-01', '2025-12-01')),
            sq(randDatetime('2025-12-01', '2026-04-01')),
        ].join(', ')
    );
}

// Чек
const receiptIds = [];
const sellers    = employeeIds.filter(id => employeePosition[id] === 'продавец-консультант');
const sellerPool = sellers.length > 0 ? sellers : employeeIds;

for (let i = 0; i < COUNT.receipts; i++) {
    const id               = uid();
    const discCardId       = Math.random() > 0.4 ? randItem(discountCardIds) : null;
    const customerFullName = Math.random() > 0.5
        ? `${faker.person.lastName()} ${faker.person.firstName()}`
        : null;
    receiptIds.push(id);
    insert('receipt',
        'id, shop_id, employee_id, discount_card_id, receipt_date, customer_full_name',
        [
            sq(id),
            sq(randItem(shopIds)),
            sq(randItem(sellerPool)),
            sq(discCardId),
            sq(randDatetime('2023-01-01', '2026-04-01')),
            sq(customerFullName),
        ].join(', ')
    );
}

// Заказ
const orderIds = [];
for (let i = 0; i < COUNT.orders; i++) {
    const id         = uid();
    const discCardId = Math.random() > 0.4 ? randItem(discountCardIds) : null;
    const comment    = Math.random() > 0.5 ? faker.lorem.sentence() : null;
    orderIds.push(id);
    insert('customer_order',
        'id, shop_id, employee_id, discount_card_id, order_date, comment',
        [
            sq(id),
            sq(randItem(shopIds)),
            sq(randItem(sellerPool)),
            sq(discCardId),
            sq(randDatetime('2023-01-01', '2026-04-01')),
            sq(comment),
        ].join(', ')
    );
}

// Накладная доставки
const couriers    = employeeIds.filter(id => employeePosition[id] === 'курьер');
const courierPool = couriers.length > 0 ? couriers : employeeIds;
const noteByOrder = {};

for (const orderId of orderIds) {
    const id        = uid();
    const orderDt   = randDatetime('2023-01-01', '2026-04-01');
    const plannedAt = randDatetime('2023-06-01', '2026-04-01');
    const actualAt  = Math.random() > 0.2 ? randDatetime(plannedAt, '2026-04-25') : null;
    const review    = Math.random() > 0.5 ? faker.lorem.sentence() : null;
    noteByOrder[orderId] = id;
    insert('delivery_note',
        'id, courier_id, order_id, order_date, planned_delivery_at, actual_delivery_at, delivery_address, customer_phone, customer_full_name, customer_signed, review, shop_mark',
        [
            sq(id),
            sq(randItem(courierPool)),
            sq(orderId),
            sq(orderDt),
            sq(plannedAt),
            sq(actualAt),
            sq(faker.location.streetAddress()),
            sq(faker.phone.number().substring(0, 20)),
            sq(`${faker.person.lastName()} ${faker.person.firstName()}`),
            bool(Math.random() > 0.1),
            sq(review),
            sq(randItem(SHOP_MARKS)),
        ].join(', ')
    );
}


// Магазин <-> Одежда
const shopClothPairs = new Set();
for (const shopId of shopIds) {
    for (const cId of randSample(clothingIds, randInt(10, 30))) {
        const key = `${shopId}|${cId}`;
        if (!shopClothPairs.has(key)) {
            shopClothPairs.add(key);
            insert('shop_clothing', 'shop_id, clothing_id, quantity',
                [sq(shopId), sq(cId), randInt(0, 30)].join(', '));
        }
    }
}

// Документ поставки <-> Одежда
const ddcPairs = new Set();
for (const docId of deliveryDocIds) {
    for (const cId of randSample(clothingIds, randInt(2, 8))) {
        const key = `${docId}|${cId}`;
        if (!ddcPairs.has(key)) {
            ddcPairs.add(key);
            insert('delivery_document_clothing', 'delivery_document_id, clothing_id, quantity, price',
                [sq(docId), sq(cId), randInt(1, 20), randFloat(500, 10000)].join(', '));
        }
    }
}

// Одежда <-> Комплект
const outfitPairs = new Set();
for (const outfitId of outfitIds) {
    for (const cId of randSample(clothingIds, randInt(2, 5))) {
        const key = `${cId}|${outfitId}`;
        if (!outfitPairs.has(key)) {
            outfitPairs.add(key);
            insert('clothing_outfit', 'clothing_id, outfit_id',
                [sq(cId), sq(outfitId)].join(', '));
        }
    }
}

// Одежда <-> Чек
for (const recId of receiptIds) {
    const used = new Set();
    for (const cId of randSample(clothingIds, randInt(1, 5))) {
        if (!used.has(cId)) {
            used.add(cId);
            insert('receipt_clothing', 'receipt_id, clothing_id, quantity, price',
                [sq(recId), sq(cId), randInt(1, 3), randFloat(1000, 20000)].join(', '));
        }
    }
}

// Одежда <-> Заказ + Одежда <-> Накладна
const orderClothMap = {};
for (const ordId of orderIds) {
    const used = new Set();
    orderClothMap[ordId] = [];
    for (const cId of randSample(clothingIds, randInt(1, 5))) {
        if (!used.has(cId)) {
            used.add(cId);
            orderClothMap[ordId].push(cId);
            insert('order_clothing', 'order_id, clothing_id, quantity, price',
                [sq(ordId), sq(cId), randInt(1, 3), randFloat(1000, 20000)].join(', '));
        }
    }
}

for (const ordId of orderIds) {
    const noteId = noteByOrder[ordId];
    if (!noteId) continue;
    const used = new Set();
    for (const cId of orderClothMap[ordId]) {
        if (!used.has(cId)) {
            used.add(cId);
            insert('delivery_note_clothing', 'delivery_note_id, clothing_id, quantity, price',
                [sq(noteId), sq(cId), randInt(1, 3), randFloat(1000, 20000)].join(', '));
        }
    }
}



fs.writeFileSync('test_data.sql', sql.join('\n'), 'utf8');

