using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class StringNumber : IScalarBody
    {
        const int HasString  = 1;
        const int HasFloat   = 2;
        const int HasInteger = 4;
        
        public StringNumber(Runtime runtime, int val)
        {
            flags = HasInteger;
            integerValue = val;
        }

        public StringNumber(Runtime runtime, string val)
        {
            flags = HasString;
            stringValue = val;
        }

        public StringNumber(Runtime runtime, double val)
        {
            flags = HasFloat;
            floatValue = val;
        }

        private StringNumber(Runtime runtime, int f, int ival, string sval, double fval)
        {
            flags = f;
            integerValue = ival;
            stringValue = sval;
            floatValue = fval;
        }

        public virtual string AsString(Runtime runtime)
        {
            if ((flags & HasString) != 0) return stringValue;
            if ((flags & HasInteger) != 0) return System.String.Format("{0:D}", integerValue);
            if ((flags & HasFloat) != 0) return System.String.Format("{0:F}", floatValue);

            throw new System.Exception();
        }
        
        public virtual int AsInteger(Runtime runtime)
        {
            if ((flags & HasString) != 0) return System.Int32.Parse(stringValue);
            if ((flags & HasInteger) != 0) return integerValue;
            if ((flags & HasFloat) != 0) return (int)floatValue;

            throw new System.Exception();
        }
        
        public virtual double AsFloat(Runtime runtime)
        {
            if ((flags & HasString) != 0) return System.Double.Parse(stringValue);
            if ((flags & HasInteger) != 0) return integerValue;
            if ((flags & HasFloat) != 0) return floatValue;

            throw new System.Exception();
        }
        
        public virtual IScalarBody CloneBody(Runtime runtime)
        {
            return new StringNumber(runtime, flags, integerValue, stringValue, floatValue);
        }

        private int flags;
        private string stringValue;
        private int integerValue;
        private double floatValue;
    }
}
