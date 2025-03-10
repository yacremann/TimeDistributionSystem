

addr_array = []
data_array = []
with open('AD9544_Config/Reciever_regs.txt', 'r') as f:
    f.readline()
    lines = f.readlines()
    for line in lines:
        addr = int(line.split(',')[0], 0)
        data = int(line.split(',')[1], 0)
        if (addr != 0):
            addr_array.append(addr)
            data_array.append(data)
    
        
with open('ad9544_regs.h', 'w') as of:
        # add header:
        of.write('const uint32_t ad9543_addrs[] = {')
        for addr in addr_array[0:-1]:
            of.write(str(addr) + ',')
        of.write(str(addr_array[-1]) + '};\n')
        
        of.write('const uint8_t ad9543_data[] = {')
        for data in data_array[0:-1]:
            of.write(str(data) + ',')
        of.write(str(data_array[-1]) + '};\n')
        
        of.write('const int ad9543_len = ' + str(len(data_array)) + ';\n');
