/**
 * 医小伴 - 通知服务
 * 封装 WebSocket 推送，供各路由调用
 * 
 * 调用方式：const notify = require('../services/notification');
 * await notify.orderStatusChanged(orderId, patientId, newStatus);
 * await notify.newOrderAvailable(orderId, serviceType);
 * await notify.chatMessage(senderId, receiverId, content);
 */

const { query } = require('../db');

/**
 * 获取全局 WebSocket 服务器实例
 */
function getWSS() {
  if (global.wss && typeof global.wss.sendToUser === 'function') {
    return global.wss;
  }
  return null;
}

/**
 * 订单状态变更通知（推送给患者）
 */
async function orderStatusChanged(orderId, patientId, newStatus, companionName = '') {
  const wss = getWSS();
  if (!wss) return;

  const statusLabels = {
    'pending': '待接单',
    'paid': '已支付',
    'confirmed': '陪诊师已接单',
    'in_progress': '服务中',
    'completed': '已完成',
    'cancelled': '已取消',
  };

  const title = '订单状态更新';
  const label = statusLabels[newStatus] || newStatus;
  let content = `您的订单状态已更新为：${label}`;

  if (newStatus === 'confirmed' && companionName) {
    content = `陪诊师 ${companionName} 已接单！`;
  } else if (newStatus === 'in_progress') {
    content = '陪诊师已开始服务，正在陪伴患者就诊';
  } else if (newStatus === 'completed') {
    content = '服务已完成，感谢您的使用！请评价本次服务';
  }

  wss.sendSystemNotification(patientId, title, content, 'order_status');

  wss.sendToUser(patientId, {
    type: 'order_update',
    data: {
      order_id: orderId,
      status: newStatus,
      status_label: label,
      timestamp: new Date().toISOString()
    }
  });
}

/**
 * 新订单通知（推送给所有在线陪诊师）
 */
async function newOrderAvailable(orderId, hospitalName, serviceType) {
  const wss = getWSS();
  if (!wss) return;

  try {
    const companions = await query(
      'SELECT user_id FROM companions WHERE is_available = 1'
    );

    for (const comp of companions) {
      if (wss.isUserOnline(comp.user_id)) {
        wss.sendSystemNotification(
          comp.user_id,
          '新订单通知',
          `【${serviceType}】${hospitalName} - 有新订单待接听`,
          'new_order'
        );
      }
    }
  } catch (e) {
    // 非关键错误
  }
}

module.exports = {
  orderStatusChanged,
  newOrderAvailable,
};
