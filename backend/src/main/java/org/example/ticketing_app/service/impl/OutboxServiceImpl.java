package org.example.ticketing_app.service.impl;

import org.example.ticketing_app.entity.Outbox;
import org.example.ticketing_app.mapper.OutboxMapper;
import org.example.ticketing_app.service.IOutboxService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 *  服务实现类
 * </p>
 *
 * @author Yucong
 * @since 2026-09-09
 */
@Service
public class OutboxServiceImpl extends ServiceImpl<OutboxMapper, Outbox> implements IOutboxService {

}
