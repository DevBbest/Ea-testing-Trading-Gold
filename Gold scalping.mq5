//+------------------------------------------------------------------+
//|                                                Gold scalping.mq5 | 
//|                                             Copyright Thanaphat. | 
//|                             https://www.youtube.com/@Bboss-ql4zm | 
//+------------------------------------------------------------------+
#property copyright "Copyright Thanaphat."
#property link      "https://www.youtube.com/@Bboss-ql4zm"
#property version   "1.00"

// พารามิเตอร์ที่ปรับแต่งได้
input double LotSize = 0.01;           // ขนาดล็อคเริ่มต้นที่ใช้ในการเทรด
input double MaxLotSize = 0.1;         // ขนาดล็อคสูงสุดที่สามารถเพิ่มได้
input int DistanceForNewOrder = 100;   // ระยะห่างจุดที่รอทำการเปิดออร์เดอร์ใหม่
input double TakeProfit = 5.0;         // ทำไรระยะสั้น
input double MaxSpread = 50.0;         // สเปรดสูงสุดที่ยอมรับได้
input double HedgeLossLimit = -3.0;    // ขาดทุนที่ยอมรับสำหรับการ Hedge
input int HedgeDistance = 50;          // ระยะห่างขั้นต่ำระหว่างการ Hedge

int buyOrders = 0;  // ตัวแปรเก็บจำนวนคำสั่ง Buy
int sellOrders = 0; // ตัวแปรเก็บจำนวนคำสั่ง Sell

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // สร้าง Timer ให้ทำงานทุก 60 วินาที
   EventSetTimer(60);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // ยกเลิก Timer เมื่อ EA ถูกปิด
   EventKillTimer();
  }
//+------------------------------------------------------------------+
// นับจำนวนคำสั่งซื้อขาย
void CountOrders()
  {
   buyOrders = 0;
   sellOrders = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      // เลือกตำแหน่งที่เปิดตามดัชนี
      if(PositionSelect(PositionGetSymbol(i)))
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
            buyOrders++;
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) 
            sellOrders++;
        }
     }
  }



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // ตรวจสอบราคา Ask และ Bid ปัจจุบัน
   double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

  // ตรวจสอบสเปรดปัจจุบัน
double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
double spread = (Ask - Bid) / point;
if (spread > MaxSpread)
   return;  // หากสเปรดมากกว่าที่กำหนด หยุดทำงานุดทำงาน

   // นับจำนวนคำสั่ง Buy และ Sell
   CountOrders();

   // ตรวจสอบเงื่อนไขระยะห่าง
   if (DistanceForNewOrderMet())
   {
      // ถ้า Buy น้อยกว่า หรือเท่ากับ Sell ให้เปิดคำสั่ง Buy
      if (buyOrders <= sellOrders)
      {
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);
         request.action = TRADE_ACTION_DEAL;
         request.symbol = Symbol();
         request.volume = LotSize;
         request.type = ORDER_TYPE_BUY;
         request.price = Ask;
         // ประกาศตัวแปร point เพื่อเก็บค่าความละเอียดของราคา
         double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
         // แก้ไขการคำนวณ TakeProfit
         request.tp = Ask + (TakeProfit * point);
         request.deviation = 2;
         request.type_filling = ORDER_FILLING_FOK;
         if(!OrderSend(request, result))
         {
             Print("Error opening Buy order: ", result.retcode);
         }
      }
      // ถ้า Sell น้อยกว่า Buy ให้เปิดคำสั่ง Sell
      else if (sellOrders < buyOrders)
      {
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);
         request.action = TRADE_ACTION_DEAL;
         request.symbol = Symbol();
         request.volume = LotSize;
         request.type = ORDER_TYPE_SELL;
         request.price = Bid;
         // ประกาศตัวแปร point เพื่อเก็บค่าความละเอียดของราคา
         double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
         // แก้ไขการคำนวณ TakeProfit สำหรับการขาย
         request.tp = Bid - (TakeProfit * point);
         request.deviation = 2;
         request.type_filling = ORDER_FILLING_FOK;
         if(!OrderSend(request, result))
         {
             Print("Error opening Sell order: ", result.retcode);
         }
      }
   }
  }
//+------------------------------------------------------------------+
//| ฟังก์ชันตรวจสอบระยะห่างเพื่อเปิดออร์เดอร์ใหม่                |
//+------------------------------------------------------------------+
bool DistanceForNewOrderMet()
  {
   // ตรวจสอบว่ามีออร์เดอร์เปิดอยู่หรือไม่
   if (PositionsTotal() == 0)
      return true;  // ไม่มีออร์เดอร์ที่เปิดอยู่ สามารถเปิดใหม่ได้

   // เลือกตำแหน่งเปิดสำหรับ Symbol ปัจจุบัน
   if (PositionSelect(Symbol()))
   {
      double lastOrderPrice = PositionGetDouble(POSITION_PRICE_OPEN); // ดึงราคาที่เปิดคำสั่งล่าสุด
      double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);   // ราคาปัจจุบันสำหรับ Buy
      // ประกาศตัวแปร point เพื่อเก็บค่าความละเอียดของราคา
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      // แก้ไขการคำนวณระยะห่าง
      double distance = MathAbs(currentPrice - lastOrderPrice) / point; // คำนวณระยะห่าง

      // ตรวจสอบว่าระยะห่างมากพอที่จะเปิดออร์เดอร์ใหม่
      if (distance >= DistanceForNewOrder)
         return true;
   }
   return false;
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // ฟังก์ชันนี้จะทำงานทุก 60 วินาที
   if (AccountInfoDouble(ACCOUNT_PROFIT) <= HedgeLossLimit) // ใช้ AccountInfoDouble
   {
      // เปิด Hedge เพื่อป้องกันความเสี่ยง
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = Symbol();
      request.volume = LotSize;
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      // ประกาศตัวแปร point เพื่อเก็บค่าความละเอียดของราคา
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
       // แก้ไขการคำนวณ TakeProfit
      request.tp = request.price - (TakeProfit * point);
      request.deviation = 2;
      request.type_filling = ORDER_FILLING_FOK;
      if(!OrderSend(request, result))
      {
          Print("Error opening Hedge order: ", result.retcode);
      }
   }
  }
//+------------------------------------------------------------------+