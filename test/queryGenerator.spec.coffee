QueryGenerator = require './../lib/queryGenerator'
expect = require('chai').expect

describe 'Query Generator', ->

  queryGenerator = null
  config = require './.data/config.json'
  beforeEach ->
    queryGenerator = new QueryGenerator config

#  describe 'includeTree', ->
#    it 'given includes should result as expected', ->
#      tree = queryGenerator._getIncludeTree [
#        'tasks'
#        'service'
#        'tasks.employee'
#        'tasks.employee.tags'
#      ]
#      expect(tree.source).to.deep.equal ['tasks', 'service']
#      expect(tree.tasks).to.deep.equal ['employee']
#      expect(tree.employee).to.deep.equal ['tags']
#
#    it 'given includes should result as expected', ->
#      tree = queryGenerator._getIncludeTree [
#        'service.form.questions.options'
#      ]
#      expect(tree.source).to.deep.equal ['service']
#      expect(tree.service).to.deep.equal ['form']
#      expect(tree.form).to.deep.equal ['questions']
#      expect(tree.questions).to.deep.equal ['options']

  describe 'select generation', ->

    describe 'including direct relationships', ->

      it 'simple select should returns sql as expected', ->
        generatedSelectSql = queryGenerator.toSql { source: 'tasks' }, config
        expect(generatedSelectSql).to.equal '
            select row_to_json(tasks) from (select
                  tasks."id" "id",
                  tasks."created_at" "createdAt"
              from tasks) as tasks;'

      it 'select with to one relationship should returns sql as expected', ->
        generatedSelectSql = queryGenerator.toSql { source: 'tasks', includes: ['employee'] }, config
        expect(generatedSelectSql).to.equal '
            select row_to_json(tasks) from (select
                  tasks."id" "id",
                  tasks."created_at" "createdAt",
                  (select row_to_json(employees)
                        from (select
                            employees."id" "id",
                            employees."name" "name"
                          from employees
                          where tasks.employee_id = employees.id)
                  as employees) as employee
            from tasks) as tasks;'

      it 'select with to many relationship should returns sql as expected', ->
        generatedSelectSql = queryGenerator.toSql { source: 'orders', includes: ['tasks'] }, config
        expect(generatedSelectSql).to.equal '
            select row_to_json(orders) from (select
                  orders."id" "id",
                  orders."description" "description",
                  (select json_agg(tasks)
                        from (select
                            tasks."id" "id",
                            tasks."created_at" "createdAt"
                          from tasks
                          where tasks.order_id = orders.id)
                  as tasks) as tasks
            from orders) as orders;'

      it 'select with both to many and to one relationship should returns sql as expected', ->
        generatedSelectSql = queryGenerator.toSql { source: 'orders', includes: ['tasks', 'service'] }, config
        expect(generatedSelectSql).to.equal '
            select row_to_json(orders) from (select
                  orders."id" "id",
                  orders."description" "description",
                  (select json_agg(tasks)
                        from (select
                            tasks."id" "id",
                            tasks."created_at" "createdAt"
                          from tasks
                          where tasks.order_id = orders.id)
                  as tasks) as tasks,
                  (select row_to_json(services)
                        from (select
                            services."id" "id",
                            services."description" "description"
                          from services
                          where services.id = orders.service_id)
                  as services) as service
            from orders) as orders;'

    describe 'including complex relationships', ->
      it 'select orders to many tasks (and tasks to one employee) should returns sql as expected', ->
        generatedSelectSql = queryGenerator.toSql { source: 'orders', includes: ['tasks', 'tasks.employee'] }, config
        expect(generatedSelectSql).to.equal '
            select row_to_json(orders) from (select
                  orders."id" "id",
                  orders."description" "description",
                  (select json_agg(tasks)
                        from (select
                            tasks."id" "id",
                            tasks."created_at" "createdAt",
                            (select row_to_json(employees)
                                  from (select
                                      employees."id" "id",
                                      employees."name" "name"
                                    from employees
                                    where tasks.employee_id = employees.id)
                            as employees) as employee
                          from tasks
                          where tasks.order_id = orders.id)
                  as tasks) as tasks
            from orders) as orders;'

      it 'select orders to one service with to one form (and form to many questions) should returns sql as expected', ->
        generatedSelectSql = queryGenerator.toSql { source: 'orders', includes: ['service.form.questions'] }, config
        expect(generatedSelectSql).to.equal '
            select row_to_json(orders) from (select
                  orders."id" "id",
                  orders."description" "description",
                  (select row_to_json(services)
                        from (select
                            services."id" "id",
                            services."description" "description",
                            (select row_to_json(services_forms)
                                  from (select
                                      services_forms."id" "id",
                                      services_forms."name" "name",
                                      (select json_agg(services_forms_questions)
                                            from (select
                                                services_forms_questions."id" "id",
                                                services_forms_questions."title" "title"
                                              from services_forms_questions
                                              where services_forms.id = services_forms_questions.form_id)
                                      as services_forms_questions) as questions
                                    from services_forms
                                    where services_forms.id = services.form_id)
                            as services_forms) as form
                          from services
                          where services.id = orders.service_id)
                  as services) as service
            from orders) as orders;'

