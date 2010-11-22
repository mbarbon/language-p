using IP5Any = org.mbarbon.p.values.IP5Any;
using P5Code = org.mbarbon.p.values.P5Code;
using P5Scalar = org.mbarbon.p.values.P5Scalar;
using P5Array = org.mbarbon.p.values.P5Array;

namespace org.mbarbon.p.runtime
{
    public enum OverloadOperation
    {
        ADD,
        SUBTRACT,
        MULTIPLY,
        DIVIDE,
        MAX,
    }

    public class Overloads
    {
        public Overloads()
        {
            methods = new string[(int)OverloadOperation.MAX];
            subroutines = new P5Code[(int)OverloadOperation.MAX];
        }

        public void AddOperation(Runtime runtime, string key,
                                 IP5Any value)
        {
            switch (key)
            {
            case "+":
                AddOperation(runtime, OverloadOperation.ADD, value);
                break;
            case "-":
                AddOperation(runtime, OverloadOperation.SUBTRACT, value);
                break;
            case "*":
                AddOperation(runtime, OverloadOperation.MULTIPLY, value);
                break;
            case "/":
                AddOperation(runtime, OverloadOperation.DIVIDE, value);
                break;
            }
        }

        public void AddOperation(Runtime runtime, OverloadOperation op,
                                 IP5Any value)
        {
            P5Scalar s = value as P5Scalar;
            int idx = (int)op;

            if (s != null && s.IsReference(runtime))
            {
                var code = s.Dereference(runtime) as P5Code;

                if (code != null)
                {
                    subroutines[idx] = code;
                    methods[idx] = null;
                    return;
                }
            }

            subroutines[idx] = null;
            methods[idx] = value.AsString(runtime);
        }

        public P5Scalar CallOperation(Runtime runtime, OverloadOperation op,
                                      P5Scalar left, P5Scalar right,
                                      bool inverted)
        {
            var args = new P5Array(runtime,
                                   inverted ? right : left,
                                   inverted ? left : right,
                                   new P5Scalar(runtime, inverted));

            if (subroutines[(int)op] != null)
            {
                return subroutines[(int)op].Call(runtime,
                                                 Opcode.ContextValues.SCALAR,
                                                 args) as P5Scalar;
            }
            else
            {
                return args.CallMethod(runtime, Opcode.ContextValues.SCALAR,
                                       methods[(int)op]) as P5Scalar;
            }
        }

        private string[] methods;
        private P5Code[] subroutines;
    }
}