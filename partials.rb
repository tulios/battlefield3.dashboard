# stolen from http://github.com/cschneid/irclogger/blob/master/lib/partials.rb
#   and made a lot more robust by me
# this implementation uses erb by default. if you want to use any other template mechanism
#   then replace `erb` on line 13 and line 17 with `haml` or whatever 
module Sinatra::Partials
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    locals = options[:locals] || {}
    if collection = options.delete(:collection) then
      
      index = 0
      
      collection.inject([]) do |buffer, member|
        partial_name = template_array[-1]
        buffer << erb(:"#{template}", options.merge(
          :layout => false,
          :locals => {
            partial_name.to_sym => member, 
            "#{partial_name}_counter".to_sym => index
          }.merge(locals))
        )
        index += 1
        buffer
      end.join("\n")
      
    else
      erb(:"#{template}", options)
    end
  end
end