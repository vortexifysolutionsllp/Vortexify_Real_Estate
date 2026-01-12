public class ScoringCriteriaEngine {

    public static void applyScoring(List<Lead> leads) {

        if (leads == null || leads.isEmpty()) return;

        /* FETCH ACTIVE SCORING RULE */
        List<Scoring_Rule__c> rules = [SELECT Id FROM Scoring_Rule__c WHERE Object__c = 'Lead' AND Active__c = true LIMIT 1];

        if (rules.isEmpty()) return;
        Scoring_Rule__c rule = rules[0];

        /* FETCH CRITERIA */
        List<Scoring_Criteria__c> criteriaList = [
            SELECT Id, Score_to_be_Awarded__c, Condition_Criteria__c, Condition_Logic__c FROM Scoring_Criteria__c WHERE Scoring_Rule__c = :rule.Id
        ];

        if (criteriaList.isEmpty()) return;

        /* FETCH CONDITIONS */
        Map<Id, List<Scoring_Condition__c>> condMap = new Map<Id, List<Scoring_Condition__c>>();

        for (Scoring_Condition__c c : [
            SELECT Field__c, Operator__c, Value__c, Scoring_Criteria__c, Index__c FROM Scoring_Condition__c
            WHERE Scoring_Criteria__c IN :criteriaList ORDER BY Index__c
        ]) {
            if (!condMap.containsKey(c.Scoring_Criteria__c)) {
                condMap.put( c.Scoring_Criteria__c, new List<Scoring_Condition__c>());
            }
            condMap.get(c.Scoring_Criteria__c).add(c);
        }

        /* APPLY SCORING (BEFORE TRIGGER) */
        for (Lead ld : leads) {

            Decimal totalScore = 0;
            List<String> awardedIds = new List<String>();

            for (Scoring_Criteria__c crit : criteriaList) {

                Boolean passed = evaluateCriteria(ld, crit,condMap.get(crit.Id));

                if (passed) {
                    totalScore += crit.Score_to_be_Awarded__c;
                    awardedIds.add(String.valueOf(crit.Id));
                }
            }

            // SAFE IN BEFORE TRIGGER
            ld.Score__c = totalScore;
            ld.Awarded_Criteria__c = String.join(awardedIds, ',');
        }
    }

    /* CRITERIA EVALUATION */
    private static Boolean evaluateCriteria(Lead ld, Scoring_Criteria__c crit, List<Scoring_Condition__c> conditions) {
        if (conditions == null || conditions.isEmpty()) return false;

        List<Boolean> results = new List<Boolean>();

        for (Scoring_Condition__c c : conditions) {

            Object fieldVal = ld.get(c.Field__c);

            results.add(
                evaluateCondition(fieldVal, c.Operator__c, c.Value__c)
            );
        }

        if (crit.Condition_Criteria__c == 'ALL') {
            return !results.contains(false);
        }

        if (crit.Condition_Criteria__c == 'ANY') {
            return results.contains(true);
        }

        return evaluateCustomLogic(crit.Condition_Logic__c, results);
    }

    /* SINGLE CONDITION */
    private static Boolean evaluateCondition( Object fieldVal, String op, String value) {
        if (op == 'IS_NULL') {
            return fieldVal == null || String.valueOf(fieldVal).trim() == '';
        }

        if (op == 'IS_NOT_NULL') {
            return fieldVal != null && String.valueOf(fieldVal).trim() != '';
        }

        if (fieldVal == null) return false;

        String fv = String.valueOf(fieldVal);

        // ---------- STRING / TEXT ----------
        if (op == '=') {
            return fv == value;
        }

        if (op == '!=') {
            return fv != value;
        }

        if (op == 'LIKE') {
            return fv.contains(value);
        }

        if (op == 'NOT LIKE') {
            return !fv.contains(value);
        }

        if (op == 'STARTS_WITH') {
            return fv.startsWith(value);
        }

        if (op == 'ENDS_WITH') {
            return fv.endsWith(value);
        }

        // ---------- NUMBER / DATE / DATETIME ----------
        if (op == '>' || op == '<' || op == '>=' || op == '<=') {

            Decimal left;
            Decimal right;

            try {
                left = Decimal.valueOf(fv);
                right = Decimal.valueOf(value);
            } catch (Exception e) {
                return false;
            }

            if (op == '>')  return left > right;
            if (op == '<')  return left < right;
            if (op == '>=') return left >= right;
            if (op == '<=') return left <= right;
        }

        // ---------- BETWEEN ----------
        if (op == 'BETWEEN') {
            if (!value.contains('AND')) return false;

            List<String> parts = value.split('AND');
            if (parts.size() != 2) return false;
         
            String fromVal = parts[0].trim();
            String toVal   = parts[1].trim();

            // 1️⃣ DATE
            if (fieldVal instanceof Date) {
                Date actual = (Date) fieldVal;
                Date fromD = Date.valueOf(fromVal);
                Date toD   = Date.valueOf(toVal);

                return actual >= fromD && actual <= toD;
            }

            // 2️⃣ DATETIME
            if (fieldVal instanceof Datetime) {
                Datetime actual = (Datetime) fieldVal;
                Datetime fromDT = Datetime.valueOf(fromVal);
                Datetime toDT   = Datetime.valueOf(toVal);

                return actual >= fromDT && actual <= toDT;
            }

            // 3️⃣ NUMBER / CURRENCY / PERCENT
            try {
                Decimal actual = Decimal.valueOf(String.valueOf(fieldVal));
                Decimal minVal = Decimal.valueOf(fromVal);
                Decimal maxVal = Decimal.valueOf(toVal);

                return actual >= minVal && actual <= maxVal;
            } catch (Exception e) {
                return false;
            }
        }


        if (op == 'IN') {
            // value format: "A,B,C"
            List<String> values = value.split(',');
            return values.contains(fv);
        }

        // ---------- MULTI PICKLIST ----------
        if (op == 'INCLUDES') {
            // field value: "A;B;C"
            Set<String> fieldValues = new Set<String>(fv.split(';'));
            return fieldValues.contains(value);
        }

        if (op == 'EXCLUDES') {
            Set<String> fieldValues = new Set<String>(fv.split(';'));
            return !fieldValues.contains(value);
        }

        return false;
    }


    /* CUSTOM LOGIC (1 AND 2 OR 3) */
    private static Boolean evaluateCustomLogic(String logic, List<Boolean> results) {
        if (String.isBlank(logic)) return false;

        // Normalize operators manually (Apex-safe)
        String expr = logic;

        expr = expr.replace('AND', '&&');
        expr = expr.replace('and', '&&');
        expr = expr.replace('OR', '||');
        expr = expr.replace('or', '||');

        // Remove spaces
        expr = expr.replace(' ', '');

        // Replace condition numbers with true/false
        for (Integer i = 0; i < results.size(); i++) {
                expr = expr.replace(
                String.valueOf(i + 1),
                String.valueOf(results[i])
            );
        }

        return evaluateBooleanExpression(expr);
    }


    private static Boolean evaluateBooleanExpression(String expr) {

        List<Boolean> values = new List<Boolean>();
        List<String> ops = new List<String>();

        Integer i = 0;
        while (i < expr.length()) {

            String ch = expr.substring(i, i + 1);

            // TRUE
            if (i + 4 <= expr.length() && expr.substring(i, i + 4) == 'true') {
                values.add(true);
                i += 4;
            }
            // FALSE
            else if (i + 5 <= expr.length() && expr.substring(i, i + 5) == 'false') {
                values.add(false);
                i += 5;
            }
            else if (ch == '(') {
                ops.add('(');
                i++;
            }
            else if (ch == ')') {
                while (!ops.isEmpty() && ops[ops.size() - 1] != '(') {
                    applyOperator(values, ops.remove(ops.size() - 1));
                }
                if (!ops.isEmpty()) {
                    ops.remove(ops.size() - 1); // remove '('
                }
                i++;
            }
            // AND / OR
            else if (i + 2 <= expr.length()) {

                String op = expr.substring(i, i + 2);

                if (op == '&&' || op == '||') {

                    while (!ops.isEmpty() &&
                           precedence(ops[ops.size() - 1]) >= precedence(op)) {
                        applyOperator(values, ops.remove(ops.size() - 1));
                    }

                    ops.add(op);
                    i += 2;
                } else {
                    i++;
                }
            }
            else {
                i++;
            }
        }

        while (!ops.isEmpty()) {
            applyOperator(values, ops.remove(ops.size() - 1));
        }

        return values.isEmpty() ? false : values[0];
    }
    
    private static Integer precedence(String op) {
        if (op == '&&') return 2;
        if (op == '||') return 1;
        return 0;
    }

    private static void applyOperator(List<Boolean> values,String operator) {
        Boolean right = values.remove(values.size() - 1);
        Boolean left = values.remove(values.size() - 1);

        if (operator == '&&') {
            values.add(left && right);
        } else if (operator == '||') {
            values.add(left || right);
        }
    }

}