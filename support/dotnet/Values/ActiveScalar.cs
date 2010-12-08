using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class P5ActiveScalar : P5Scalar
    {
        public override P5Scalar AsScalar(Runtime runtime)
        {
            return (body as P5ActiveScalarBody).Get(runtime);
        }

        public override P5Scalar Assign(Runtime runtime, IP5Any other)
        {
            (body as P5ActiveScalarBody).Set(runtime, other);

            return this;
        }

        public override bool IsDefined(Runtime runtime)
        {
            return (body as P5ActiveScalarBody).Get(runtime).IsDefined(runtime);
        }
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

        public virtual bool IsInteger(Runtime runtime)
        {
            return Get(runtime).Body.IsInteger(runtime);
        }

        public virtual bool IsString(Runtime runtime)
        {
            return Get(runtime).Body.IsString(runtime);
        }

        public virtual bool IsFloat(Runtime runtime)
        {
            return Get(runtime).Body.IsFloat(runtime);
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

        public virtual int GetPos(Runtime runtime)
        {
            return Get(runtime).GetPos(runtime);
        }

        public virtual int GetPos(Runtime runtime, out bool pos_set)
        {
            return Get(runtime).GetPos(runtime, out pos_set);
        }

        public virtual int Length(Runtime runtime)
        {
            return Get(runtime).Length(runtime);
        }

        public virtual void SetPos(Runtime runtime, int pos, bool pos_set)
        {
            Get(runtime).SetPos(runtime, pos, pos_set);
        }

        public virtual void Set(Runtime runtime, IP5Any other)
        {
            throw new System.Exception("Ouch!");
        }

        public virtual P5Scalar Get(Runtime runtime)
        {
            throw new System.Exception("Ouch!");
        }
    }
}
