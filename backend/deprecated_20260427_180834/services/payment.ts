import crypto from 'crypto';
import axios from 'axios';
import db from '../config/database';
import { v4 as uuidv4 } from 'uuid';

export class PaymentService {
  // 微信支付
  static async createWechatPayment(orderNo: string, amount: number, openid?: string) {
    const paymentNo = `WX${Date.now()}${Math.random().toString(36).substr(2, 6)}`;
    
    // 保存支付记录
    await db('payments').insert({
      payment_no: paymentNo,
      order_no: orderNo,
      type: 'wechat',
      amount,
      status: 'pending'
    });
    
    // 调用微信支付API
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const nonceStr = Math.random().toString(36).substr(2, 15);
    
    const params: any = {
      appid: process.env.WECHAT_APP_ID,
      mch_id: process.env.WECHAT_MCH_ID,
      nonce_str: nonceStr,
      body: '医小伴陪诊服务',
      out_trade_no: paymentNo,
      total_fee: Math.round(amount * 100), // 转换为分
      spbill_create_ip: '127.0.0.1',
      notify_url: `${process.env.API_BASE_URL}/payment/wechat/notify`,
      trade_type: openid ? 'JSAPI' : 'NATIVE',
      time_expire: new Date(Date.now() + 30 * 60 * 1000).toISOString().replace(/\.\d{3}Z$/, '')
    };
    
    if (openid) {
      params.openid = openid;
    }
    
    // 生成签名
    params.sign = this.generateWechatSign(params);
    
    // 调用微信统一下单接口
    const xmlData = this.objectToXml(params);
    const response = await axios.post(
      'https://api.mch.weixin.qq.com/pay/unifiedorder',
      xmlData,
      { headers: { 'Content-Type': 'text/xml' } }
    );
    
    const result = this.xmlToObject(response.data);
    
    if (result.return_code === 'SUCCESS' && result.result_code === 'SUCCESS') {
      let paymentData = {};
      
      if (openid) {
        // JSAPI支付参数
        const jsapiParams = {
          appId: process.env.WECHAT_APP_ID,
          timeStamp: timestamp,
          nonceStr: nonceStr,
          package: `prepay_id=${result.prepay_id}`,
          signType: 'MD5'
        };
        
        jsapiParams.paySign = this.generateWechatSign(jsapiParams);
        paymentData = jsapiParams;
      } else {
        // NATIVE支付返回二维码链接
        paymentData = { code_url: result.code_url };
      }
      
      // 更新支付记录
      await db('payments')
        .where('payment_no', paymentNo)
        .update({
          payment_data: JSON.stringify(paymentData),
          updated_at: new Date()
        });
      
      return {
        payment_no: paymentNo,
        payment_data: paymentData
      };
    } else {
      throw new Error(result.return_msg || '微信支付创建失败');
    }
  }
  
  // 支付宝支付
  static async createAlipayPayment(orderNo: string, amount: number) {
    const paymentNo = `ALI${Date.now()}${Math.random().toString(36).substr(2, 6)}`;
    
    // 保存支付记录
    await db('payments').insert({
      payment_no: paymentNo,
      order_no: orderNo,
      type: 'alipay',
      amount,
      status: 'pending'
    });
    
    const AlipaySdk = require('alipay-sdk').default;
    const alipaySdk = new AlipaySdk({
      appId: process.env.ALIPAY_APP_ID,
      privateKey: process.env.ALIPAY_PRIVATE_KEY,
      alipayPublicKey: process.env.ALIPAY_PUBLIC_KEY,
      gateway: 'https://openapi.alipay.com/gateway.do'
    });
    
    const bizContent = {
      out_trade_no: paymentNo,
      product_code: 'FAST_INSTANT_TRADE_PAY',
      total_amount: amount.toFixed(2),
      subject: '医小伴陪诊服务',
      body: '专业医疗陪诊服务',
      time_expire: new Date(Date.now() + 30 * 60 * 1000).toISOString().replace(/\.\d{3}Z$/, '')
    };
    
    const result = await alipaySdk.pageExec('alipay.trade.page.pay', {
      method: 'POST',
      bizContent,
      returnUrl: `${process.env.FRONTEND_URL}/payment/success`,
      notifyUrl: `${process.env.API_BASE_URL}/payment/alipay/notify`
    });
    
    // 更新支付记录
    await db('payments')
      .where('payment_no', paymentNo)
      .update({
        payment_data: JSON.stringify({ form: result }),
        updated_at: new Date()
      });
    
    return {
      payment_no: paymentNo,
      payment_data: { form: result }
    };
  }
  
  // 微信支付签名
  private static generateWechatSign(params: any): string {
    // 按参数名ASCII字典序排序
    const sortedKeys = Object.keys(params).sort();
    const stringA = sortedKeys
      .filter(key => params[key] && key !== 'sign')
      .map(key => `${key}=${params[key]}`)
      .join('&');
    
    const stringSignTemp = `${stringA}&key=${process.env.WECHAT_API_KEY}`;
    return crypto.createHash('md5').update(stringSignTemp).digest('hex').toUpperCase();
  }
  
  // 对象转XML
  private static objectToXml(obj: any): string {
    let xml = '<xml>';
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        xml += `<${key}>${obj[key]}</${key}>`;
      }
    }
    xml += '</xml>';
    return xml;
  }
  
  // XML转对象
  private static xmlToObject(xml: string): any {
    const parser = require('xml2js').Parser({ explicitArray: false });
    let result: any = {};
    
    parser.parseString(xml, (err: any, res: any) => {
      if (!err) {
        result = res.xml;
      }
    });
    
    return result;
  }
  
  // 处理支付回调
  static async handlePaymentCallback(paymentNo: string, transactionId: string) {
    const payment = await db('payments')
      .where('payment_no', paymentNo)
      .first();
    
    if (!payment || payment.status !== 'pending') {
      return false;
    }
    
    // 更新支付状态
    await db('payments')
      .where('payment_no', paymentNo)
      .update({
        status: 'paid',
        transaction_id: transactionId,
        updated_at: new Date()
      });
    
    // 更新订单状态
    await db('orders')
      .where('order_no', payment.order_no)
      .update({
        status: 'accepted',
        updated_at: new Date()
      });
    
    return true;
  }
  
  // 退款处理
  static async refundPayment(paymentNo: string, refundAmount: number) {
    const payment = await db('payments')
      .where('payment_no', paymentNo)
      .where('status', 'paid')
      .first();
    
    if (!payment) {
      throw new Error('支付记录不存在或未支付');
    }
    
    const refundNo = `REF${Date.now()}${Math.random().toString(36).substr(2, 6)}`;
    
    // 根据支付类型处理退款
    if (payment.type === 'wechat') {
      // 微信退款逻辑
      const params = {
        appid: process.env.WECHAT_APP_ID,
        mch_id: process.env.WECHAT_MCH_ID,
        nonce_str: Math.random().toString(36).substr(2, 15),
        transaction_id: payment.transaction_id,
        out_refund_no: refundNo,
        total_fee: Math.round(payment.amount * 100),
        refund_fee: Math.round(refundAmount * 100),
        notify_url: `${process.env.API_BASE_URL}/payment/wechat/refund/notify`
      };
      
      params.sign = this.generateWechatSign(params);
      
      const xmlData = this.objectToXml(params);
      const response = await axios.post(
        'https://api.mch.weixin.qq.com/secapi/pay/refund',
        xmlData,
        {
          headers: { 'Content-Type': 'text/xml' },
          httpsAgent: new (require('https').Agent)({
            pfx: require('fs').readFileSync(process.env.WECHAT_CERT_PATH!),
            passphrase: process.env.WECHAT_MCH_ID
          })
        }
      );
      
      const result = this.xmlToObject(response.data);
      
      if (result.return_code === 'SUCCESS' && result.result_code === 'SUCCESS') {
        await db('payments')
          .where('payment_no', paymentNo)
          .update({
            status: 'refunded',
            updated_at: new Date()
          });
        
        return { success: true, refund_no: refundNo };
      } else {
        throw new Error(result.return_msg || '微信退款失败');
      }
    } else if (payment.type === 'alipay') {
      // 支付宝退款逻辑
      const AlipaySdk = require('alipay-sdk').default;
      const alipaySdk = new AlipaySdk({
        appId: process.env.ALIPAY_APP_ID,
        privateKey: process.env.ALIPAY_PRIVATE_KEY,
        alipayPublicKey: process.env.ALIPAY_PUBLIC_KEY
      });
      
      const bizContent = {
        out_trade_no: paymentNo,
        refund_amount: refundAmount.toFixed(2),
        out_request_no: refundNo
      };
      
      const result = await alipaySdk.exec('alipay.trade.refund', { bizContent });
      
      if (result.code === '10000') {
        await db('payments')
          .where('payment_no', paymentNo)
          .update({
            status: 'refunded',
            updated_at: new Date()
          });
        
        return { success: true, refund_no: refundNo };
      } else {
        throw new Error(result.msg || '支付宝退款失败');
      }
    }
    
    throw new Error('不支持的支付类型');
  }
}