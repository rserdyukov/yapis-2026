package Ohm
  model FromVoltage
    parameter Real R = 2;
    Real v;
    Real i;
  equation
    v = R * i;
    v = 10;
  end FromVoltage;

  model FromCurrent
    parameter Real R = 2;
    Real v;
    Real i;
  equation
    v = R * i;
    i = 3;
  end FromCurrent;
end Ohm;
