package org.example.ticketing_app.service.impl;

import org.example.ticketing_app.entity.Organization;
import org.example.ticketing_app.mapper.OrganizationMapper;
import org.example.ticketing_app.service.IOrganizationService;
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
public class OrganizationServiceImpl extends ServiceImpl<OrganizationMapper, Organization> implements IOrganizationService {

}
