import axios from 'axios';
import db from '../config/database';

export class AIService {
  // 通义千问API调用
  static async qwenChat(messages: Array<{ role: string; content: string }>) {
    try {
      const response = await axios.post(
        'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation',
        {
          model: 'qwen-plus',
          input: {
            messages
          },
          parameters: {
            result_format: 'message',
            temperature: 0.7,
            top_p: 0.8,
            max_tokens: 2000
          }
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.ALIYUN_BAILIAN_API_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );
      
      return response.data.output.text;
    } catch (error: any) {
      console.error('通义千问API调用失败:', error.response?.data || error.message);
      throw new Error('AI服务暂时不可用，请稍后重试');
    }
  }
  
  // AI问诊
  static async medicalConsultation(userId: number, symptoms: string) {
    const prompt = `你是一位专业的医疗助手。用户描述的症状如下：

${symptoms}

请根据以下步骤进行分析：
1. 可能的疾病方向（列出2-3个最可能的方向）
2. 建议的检查项目
3. 是否需要立即就医
4. 日常注意事项
5. 建议挂什么科室

请用专业但易懂的语言回答，避免使用过于专业的术语。`;

    const messages = [
      {
        role: 'system',
        content: '你是一位专业的医疗助手，请根据用户的症状描述提供专业的医疗建议。注意：你的建议仅供参考，不能替代专业医生的诊断。'
      },
      {
        role: 'user',
        content: prompt
      }
    ];
    
    const diagnosis = await this.qwenChat(messages);
    
    // 保存问诊记录
    const [recordId] = await db('ai_consultations').insert({
      user_id: userId,
      symptoms,
      diagnosis,
      created_at: new Date(),
      updated_at: new Date()
    });
    
    return {
      record_id: recordId,
      diagnosis,
      disclaimer: '本建议由AI生成，仅供参考，不能替代专业医生的诊断。如有不适，请及时就医。'
    };
  }
  
  // 报告解读
  static async reportAnalysis(userId: number, reportText: string, reportType: string) {
    const prompt = `请解读以下${reportType}报告：

${reportText}

请按照以下格式提供解读：
1. 报告概述（用通俗语言解释这份报告是什么）
2. 关键指标分析（列出异常指标并解释含义）
3. 可能的原因（导致这些异常的可能原因）
4. 建议措施（下一步应该做什么）
5. 注意事项（需要特别注意的事项）

请用通俗易懂的语言，避免过于专业的术语。`;

    const messages = [
      {
        role: 'system',
        content: '你是一位专业的医疗报告解读助手，请用通俗易懂的语言帮助用户理解医疗报告。'
      },
      {
        role: 'user',
        content: prompt
      }
    ];
    
    const analysis = await this.qwenChat(messages);
    
    // 保存解读记录
    const [recordId] = await db('ai_consultations').insert({
      user_id: userId,
      symptoms: `报告解读：${reportType}`,
      diagnosis: analysis,
      report_analysis: JSON.stringify({
        report_type: reportType,
        analysis,
        analyzed_at: new Date()
      }),
      created_at: new Date(),
      updated_at: new Date()
    });
    
    return {
      record_id: recordId,
      analysis,
      disclaimer: '本解读由AI生成，仅供参考，不能替代专业医生的诊断。请以医生的专业意见为准。'
    };
  }
  
  // 智能客服
  static async customerService(query: string, context?: any) {
    const systemPrompt = `你是医小伴陪诊APP的智能客服助手。请根据用户的问题提供准确、友好的回答。

关于医小伴的服务信息：
1. 服务类型：小时陪诊、全天陪诊、定制服务
2. 服务流程：预约->匹配陪诊师->服务->支付->评价
3. 价格：小时陪诊80元/小时，全天陪诊500元/天
4. 陪诊师：均经过严格审核和培训
5. 支付方式：微信支付、支付宝、余额支付
6. 退款政策：服务开始前可全额退款，服务开始后按比例退款

如果用户的问题超出你的知识范围，请建议用户联系人工客服（工作时间：9:00-21:00）。

当前上下文：${JSON.stringify(context || {})}`;

    const messages = [
      {
        role: 'system',
        content: systemPrompt
      },
      {
        role: 'user',
        content: query
      }
    ];
    
    return await this.qwenChat(messages);
  }
  
  // 症状自检
  static async symptomChecker(symptoms: string[], userInfo?: any) {
    const symptomText = symptoms.join('，');
    const userInfoText = userInfo ? `用户信息：${JSON.stringify(userInfo)}` : '';
    
    const prompt = `用户报告了以下症状：${symptomText}
${userInfoText}

请进行症状自检分析：
1. 症状严重程度评估（轻度/中度/重度）
2. 可能的紧急情况（是否需要立即就医）
3. 建议的自我护理措施
4. 建议的就医科室
5. 需要警惕的危险信号

请用分级的方式回答：
- 绿色：可以自我观察，无需立即就医
- 黄色：建议近期就医检查
- 红色：需要立即就医`;

    const messages = [
      {
        role: 'system',
        content: '你是一位症状自检助手，请根据用户的症状描述提供风险评估和建议。'
      },
      {
        role: 'user',
        content: prompt
      }
    ];
    
    return await this.qwenChat(messages);
  }
  
  // 用药咨询
  static async medicationConsultation(medication: string, condition: string) {
    const prompt = `用户正在使用药物：${medication}
治疗疾病：${condition}

请提供用药指导：
1. 药物作用机制（通俗解释）
2. 正确服用方法
3. 常见副作用及处理方法
4. 药物相互作用提醒
5. 注意事项和禁忌

重要：必须强调以下内容：
- 本建议不能替代医生或药师的指导
- 请严格遵医嘱用药
- 如有不适立即就医`;

    const messages = [
      {
        role: 'system',
        content: '你是一位用药指导助手，请提供准确的用药信息，但必须强调不能替代专业医疗建议。'
      },
      {
        role: 'user',
        content: prompt
      }
    ];
    
    return await this.qwenChat(messages);
  }
  
  // 健康知识问答
  static async healthQA(question: string) {
    const prompt = `用户提问：${question}

请提供准确、科学的健康知识回答。要求：
1. 基于权威医学知识
2. 用通俗易懂的语言
3. 注明信息来源（如：根据XX医学指南）
4. 如有争议，说明不同观点
5. 强调个体差异，建议咨询医生

如果问题涉及疾病诊断或治疗，必须强调需要医生面诊。`;

    const messages = [
      {
        role: 'system',
        content: '你是一位健康知识科普助手，请提供准确、科学的健康信息。'
      },
      {
        role: 'user',
        content: prompt
      }
    ];
    
    return await this.qwenChat(messages);
  }
}