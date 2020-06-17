        
        # 先根据运行时设置进行过滤，然后再判断打印控制
        res_ids = [rec['id'] for rec in print_data[self.env.get(res_model)._table]]
        self.env['print.control'].validation(res_model, res_ids)
