package org.example.ticketing_app.service.impl;

import org.example.ticketing_app.entity.Ticket;
import org.example.ticketing_app.mapper.TicketMapper;
import org.example.ticketing_app.service.ITicketService;
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
public class TicketServiceImpl extends ServiceImpl<TicketMapper, Ticket> implements ITicketService {

}
