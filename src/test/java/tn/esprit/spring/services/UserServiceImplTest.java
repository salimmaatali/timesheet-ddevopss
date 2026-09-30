package tn.esprit.spring.services;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.MethodOrderer.OrderAnnotation;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import tn.esprit.spring.entities.Role;
import tn.esprit.spring.entities.User;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

// Test d'integration JUnit : demarre Spring avec la base H2 en memoire
// (voir src/test/resources/application.properties).
@SpringBootTest
@TestMethodOrder(OrderAnnotation.class)
class UserServiceImplTest {

	@Autowired
	IUserService us;

	// id de l'utilisateur cree au test 1, reutilise par les tests suivants
	static Long userId;

	@Test
	@Order(1)
	void testAddUser() throws ParseException {
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
		Date d = dateFormat.parse("2015-03-23");
		User u = new User("Mayssa1", "Mayssa1", d, Role.INGENIEUR);
		User userAdded = us.addUser(u);
		Assertions.assertNotNull(userAdded.getId());
		Assertions.assertEquals(u.getLastName(), userAdded.getLastName());
		userId = userAdded.getId();
	}

	@Test
	@Order(2)
	void testRetrieveAllUsers() {
		List<User> listUsers = us.retrieveAllUsers();
		Assertions.assertFalse(listUsers.isEmpty());
	}

	@Test
	@Order(3)
	void testModifyUser() throws ParseException {
		SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
		Date d = dateFormat.parse("2015-03-23");
		User u = new User(userId, "Mayssa122222222", "Mayssa", d, Role.INGENIEUR);
		User userUpdated = us.updateUser(u);
		Assertions.assertEquals(u.getLastName(), userUpdated.getLastName());
	}

	@Test
	@Order(4)
	void testRetrieveUser() {
		User userRetrieved = us.retrieveUser(String.valueOf(userId));
		Assertions.assertEquals(userId, userRetrieved.getId());
	}

	@Test
	@Order(5)
	void testDeleteUser() {
		us.deleteUser(String.valueOf(userId));
		Assertions.assertNull(us.retrieveUser(String.valueOf(userId)));
	}
}
