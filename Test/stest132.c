int g1, g2;

void testdiv1(unsigned short a, int b)
{
    g1 = a / b;  // should be integer divide
    g2 = b % a; // also should be integer divide
}

void testdiv2(unsigned short a, unsigned int b)
{
    g1 = a / b;  // should be unsigned divide
    g2 = b % a; // also should be unsigned divide
}
