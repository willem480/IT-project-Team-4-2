// lib/config.dart

class ApiConfig {
  //local url
  static const String baseUrl = 'http://127.0.0.1:8080';

  static String getUser(int userId) => '$baseUrl/profilePage/getUser?userId=$userId';
  static const String createTicket = '$baseUrl/ticket/createTicket';
  static String getTicketComment(int ticketId, int operatorId) =>
      '$baseUrl/ticketComment/getTicketComments?ticketId=$ticketId&operatorId=$operatorId';
  static String postTicketComment(int userId, int ticketId, String comment) =>
      '$baseUrl/ticketComment/postComment?userId=$userId&ticketId=$ticketId&comment=$comment';
  static String completeTicket(int ticketId) => '$baseUrl/ticket/complete%20ticket?ticketId=$ticketId';
  static String deallocateTicket(int ticketId, int operatorId) =>
      '$baseUrl/ticketAssignment/deallocateTicket?ticketId=$ticketId&operatorId=$operatorId';
  // static String getUserByEmail = '$baseUrl/user/getUsersByEmail';
  static String deleteComment(int operatorId, int commentId) =>
      '$baseUrl/ticketComment/deleteComment?operatorId=$operatorId&ticketCommentId=$commentId';
  static String delegateJobIndividual(int ticketId, int currentUserId)=>"$baseUrl/ticketAssignment/delegateJobIndividual?ticketId=$ticketId&assigneeId=$currentUserId";
  static String getOrganization(int currentUserId) => '$baseUrl/organization/getOrganizations?viewerUserId=$currentUserId';
  static String getOpenTicketsByKeyword(String keyword) => '$baseUrl/ticket/getOpenTicketsByKeyword?keyword=$keyword';
  static String getAcceptedJobsWithFilter(int assigneeId) => '$baseUrl/ticketAssignment/getAcceptedJobsWithFilter?assigneeID=$assigneeId';
  static String getOrganizationManagers(int organizationId) =>  '$baseUrl/organization/getOrganizationManagers?organizationId=$organizationId';
  static String getOrganizationTeams(int organizationId, int userId) => '$baseUrl/organization/getOrganizationTeams?organizationId=$organizationId&viewerUserId=$userId';





}