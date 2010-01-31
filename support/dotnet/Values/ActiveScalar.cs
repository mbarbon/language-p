using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5ActiveScalar : P5Scalar
    {
    }

    public class P5ActiveScalarBody : IP5ScalarBody
    {
        public virtual IP5ScalarBody CloneBody(Runtime runtime)
        {
            return Get(runtime).Body.CloneBody(runtime);
        }

        public virtual string AsString(Runtime runtime)
        {
            return Get(runtime).AsString(runtime);
        }

        public virtual int AsInteger(Runtime runtime)
        {
            return Get(runtime).AsInteger(runtime);
        }

        public virtual double AsFloat(Runtime runtime)
        {
            return Get(runtime).AsFloat(runtime);
        }

        public virtual bool AsBoolean(Runtime runtime)
        {
            return Get(runtime).AsBoolean(runtime);
        }

        public virtual P5Scalar ReferenceType(Runtime runtime)
        {
            return Get(runtime).ReferenceType(runtime);
        }

        public virtual P5Scalar DereferenceScalar(Runtime runtime)
        {
            return Get(runtime).DereferenceScalar(runtime);
        }

        public virtual P5Array DereferenceArray(Runtime runtime)
        {
            return Get(runtime).DereferenceArray(runtime);
        }

        public virtual P5Hash DereferenceHash(Runtime runtime)
        {
            return Get(runtime).DereferenceHash(runtime);
        }

        public virtual P5Typeglob DereferenceGlob(Runtime runtime)
        {
            return Get(runtime).DereferenceGlob(runtime);
        }

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            return Get(runtime).DereferenceSubroutine(runtime);
        }

        protected virtual void Set(Runtime runtime, IP5Any other)
        {
            throw new System.Exception("Ouch!");
        }

        protected virtual P5Scalar Get(Runtime runtime)
        {
            throw new System.Exception("Ouch!");
        }
    }
}
