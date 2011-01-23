using Runtime = org.mbarbon.p.runtime.Runtime;
using Builtins = org.mbarbon.p.runtime.Builtins;

namespace org.mbarbon.p.values
{
    public class P5StringNumber : IP5ScalarBody
    {
        internal const int HasString  = 1;
        internal const int HasFloat   = 2;
        internal const int HasInteger = 4;

        public P5StringNumber(Runtime runtime, int val)
        {
            flags = HasInteger;
            integerValue = val;
        }

        public P5StringNumber(Runtime runtime, string val)
        {
            flags = HasString;
            stringValue = val;
        }

        public P5StringNumber(Runtime runtime, double val)
        {
            flags = HasFloat;
            floatValue = val;
        }

        private P5StringNumber(Runtime runtime, int f, int ival, string sval, double fval)
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
            if ((flags & HasFloat) != 0) return System.String.Format("{0:0.#########}", floatValue);

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

        public virtual bool IsInteger(Runtime runtime)
        {
            return (flags & HasInteger) != 0;
        }

        public virtual bool IsString(Runtime runtime)
        {
            return (flags & HasString) != 0;
        }

        public virtual bool IsFloat(Runtime runtime)
        {
            return (flags & HasFloat) != 0;
        }

        public virtual bool AsBoolean(Runtime runtime)
        {
            return    ((flags & HasInteger) != 0 && integerValue != 0)
                   || ((flags & HasString) != 0 && stringValue.Length != 0)
                   || ((flags & HasFloat) != 0 && floatValue != 0);
        }

        public void SetString(Runtime runtime, string value)
        {
            pos = -1;
            flags = HasString;
            stringValue = value;
        }

        public void SetInteger(Runtime runtime, int value)
        {
            pos = -1;
            flags = HasInteger;
            integerValue = value;
            stringValue = null;
        }

        public void SetFloat(Runtime runtime, double value)
        {
            pos = -1;
            flags = HasFloat;
            floatValue = value;
            stringValue = null;
        }

        public virtual int Length(Runtime runtime)
        {
            return AsString(runtime).Length;
        }

        public virtual IP5ScalarBody CloneBody(Runtime runtime)
        {
            return new P5StringNumber(runtime, flags, integerValue, stringValue, floatValue);
        }

        internal void Increment(Runtime runtime)
        {
            pos = -1;

            if ((flags & HasFloat) != 0)
                floatValue = floatValue + 1.0;
            if ((flags & HasInteger) != 0)
                integerValue = integerValue + 1;
            // TODO string increment
        }

        internal void Decrement(Runtime runtime)
        {
            pos = -1;

            if ((flags & HasFloat) != 0)
                floatValue = floatValue - 1.0;
            if ((flags & HasInteger) != 0)
                integerValue = integerValue - 1;
            // TODO string decrement
        }

        public virtual string ReferenceTypeString(Runtime runtime)
        {
            return "SCALAR";
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            return Builtins.SymbolicReferenceScalar(runtime, this, true);
        }

        public virtual IP5Array DereferenceArray(Runtime runtime)
        {
            return Builtins.SymbolicReferenceArray(runtime, this, true);
        }

        public virtual P5Hash DereferenceHash(Runtime runtime)
        {
            return Builtins.SymbolicReferenceHash(runtime, this, true);
        }

        public virtual P5Typeglob DereferenceGlob(Runtime runtime)
        {
            return Builtins.SymbolicReferenceGlob(runtime, this, true);
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            return Builtins.SymbolicReferenceCode(runtime, this, true);
        }

        public virtual P5Handle DereferenceHandle(Runtime runtime)
        {
            return Builtins.SymbolicReferenceHandle(runtime, this, true);
        }

        public virtual int GetPos(Runtime runtime)
        {
            return pos;
        }

        public virtual int GetPos(Runtime runtime, out bool _pos_set)
        {
            _pos_set = pos_set;

            return pos;
        }

        public virtual void SetPos(Runtime runtime, int _pos, bool _pos_set)
        {
            pos = _pos;
            pos_set = _pos_set;
        }

        internal int flags;
        internal int pos = -1;
        internal bool pos_set = false;
        internal string stringValue;
        internal int integerValue;
        internal double floatValue;
    }
}
